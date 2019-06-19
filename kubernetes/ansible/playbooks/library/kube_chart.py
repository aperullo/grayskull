#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = """
---
module: kube_chart
short_description: Deploy Helm charts with Kubernetes
description:
  - Download Helm charts as .tgz and render kubernetes manifest with helm template, then deploy with kubectl apply
options:
    namespace:
        required: false
        default: null
        description:
          - The namespace the chart will be deployed into
    chart_src:
        required: true
        default: null
        description:
          - The address of the Helm chart to be downloaded
    chart_version:
        required: true
        default: null
        description:
          - The version of the Helm chart to be downloaded
    chart_dest:
        required: true
        default: null
        description:
          - The directory where the Helm chart should be downloaded to
    path_to_values:
        required: false
        default: null
        description:
          - The path to the values file to be used with the chart
    bin_dir:
        required: true
        default: null
        description:
          - The directory where helm and kubectl are located
    render_only:
        required: false
        default: false
        description:
          - A flag to only render the templates and not deploy the chart
requirements:
  - kubectl
  - helm
"""

EXAMPLES = """
- name: Download and apply PostgreSQL
  kube_chart:
    namespace: postgres
    chart_src: stable/postgresql
    chart_version: 5.3.5
    chart_dest: /dest
    path_to_values: /dest/postgresql-value.yml
    bin_dir: /usr/local/bin

"""

class KubeManager(object):

    def __init__(self, module):

        self.module = module

        # Find path of where the command is.
        self.bin_dir = module.params.get('bin_dir')
        if self.bin_dir is None:
            self.bin_dir =  module.get_bin_path('bin_dir', True)

        # Passed in arguments to the module
        self.namespace = module.params.get('namespace')
        self.chart_dest = module.params.get('chart_dest')
        self.chart_src = module.params.get('chart_src')
        self.chart_version = module.params.get('chart_version')
        self.path_to_values = module.params.get('path_to_values')
        self.render_only = module.params.get('render_only')

        # Constructed values for use in saving and applying the chart
        self.chart_name = self.chart_src.split('/')[-1]
        self.chart_name_ver = self.chart_name + '-' + self.chart_version

    # Runs the commands after joining them and also handles failing commands.
    def _execute(self, cmd, use_unsafe_shell=False):
        try:
            rc, out, err = self.module.run_command(' '.join(cmd), use_unsafe_shell=use_unsafe_shell)
            if rc != 0:
                self.module.fail_json(
                    msg="error running ({}) command (rc={}), out='{}', err='{}'".format(' '.join(cmd), rc, out, err))
        except Exception as exc:
            self.module.fail_json(
                msg='error running ({}) command: {}'.format(' '.join(cmd), str(exc)))
        return out.splitlines()


    def fetch_and_apply_chart(self):
        # helm template with values.yml

        self.kubectl_cmd = ['{}/kubectl'.format(self.bin_dir)]
        self.helm_cmd = ['{}/helm'.format(self.bin_dir)]

        # The path to the file resulting from the operation, missing the file extension
        result_path = ''.join([self.chart_dest, '/', self.chart_name_ver])

        # Download the helm chart
        fetch_cmd = self.helm_cmd[:]
        fetch_cmd.append('fetch')
        fetch_cmd.append(self.chart_src)
        fetch_cmd.append('-d')
        fetch_cmd.append(self.chart_dest)
        fetch_cmd.append('--version')
        fetch_cmd.append(self.chart_version)

        result = self._execute(fetch_cmd)


        # Use 'helm template' to render a template, replacing defaults with values from provided values file. Then save the resulting manifest to a file
        template_cmd = self.helm_cmd[:]
        template_cmd.append('template')
        template_cmd.append(result_path + '.tgz')
        # only if a values file was provided do we need the --values arg.
        if self.path_to_values:
            template_cmd.append('--values')
            template_cmd.append(self.path_to_values)
        template_cmd.append('>')
        template_cmd.append(result_path + '.yml')
        if self.namespace:
            template_cmd.append('--namespace')
            template_cmd.append(self.namespace)

        result = self._execute(template_cmd, True)

        # Apply the rendered manifest. Or not if render_only
        if not self.render_only:

            apply_cmd = self.kubectl_cmd[:]
            apply_cmd.append('apply')
            apply_cmd.append('-f')
            apply_cmd.append(result_path + '.yml')
            if self.namespace:
                apply_cmd.append('-n')
                apply_cmd.append(self.namespace)

            result = self._execute(apply_cmd)

        return result


def main():

    module = AnsibleModule(
        argument_spec =
        {
            'namespace': {'required': False, 'type': 'str'},
            'chart_src': {'required': True, 'type': 'str'},
            'chart_version': {'required': True, 'type': 'str'},
            'chart_dest': {'required': True, 'type': 'str'},
            'path_to_values': {'required': False, 'type': 'str'},
            'render_only': {'default': False, 'type': 'bool'},
            'bin_dir': {'required': True, 'type': 'str'}
        }
    )
    manager = KubeManager(module)


    result = manager.fetch_and_apply_chart()
    # Do any of the lines returned in result contain 'configured'. If so, something probably was changed.
    # Note: kubectl will reported configured for some resources even if they haven't changed. Secrets for example.
    changed = any(map(lambda line: 'configured' in line, result))

    module.exit_json(changed=changed,
                     msg='success: {}'.format(result)
                     )


from ansible.module_utils.basic import *
if __name__ == '__main__':
    main()
