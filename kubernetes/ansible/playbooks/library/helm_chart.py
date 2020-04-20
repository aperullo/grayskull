#!/usr/bin/python
# -*- coding: utf-8 -*-

from re import compile, findall

DOCUMENTATION = """
---
module: helm_chart
short_description: Deploy Helm charts with Kubernetes
description:
  Apply a helm chart using a values file, either installing, upgrading, or leaving it alone. 
  Used to fix issue of helm failing to deploy if chart already exists. Goal is to make the deploy idempotent.
options:
    name:
        required: true
        default: null
        description:
          - The name of the release
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
    upgrade:
        required: false
        default: false
        description:
          - A flag for whether this should upgrade the existing chart or leave it alone. Only matters if chart is already deployed.
    state:
        required: false
        choices: ['present', 'absent', 'latest']
        default: present
        description:
          - present checks existence or creating if definition file provided,
            absent handles deleting resource(s) if exists,
            latest creates or upgrades based on existence

    atomic:
        required: false
        default: false
        description:
          - A flag for whether this should try to install atomically.

requirements:
  - kubectl
  - helm
"""

EXAMPLES = """
- name: Download and apply PostgreSQL
  helm_chart:
    name: gsp
    namespace: postgres
    bin_dir: /usr/local/bin
    chart_src: stable/postgresql
    chart_version: 5.3.11
    state: present
    path_to_values: "/dest/postgresql-value.yml"


"""

class KubeManager(object):

    def __init__(self, module):

        self.module = module

        # Find path of where the command is.
        self.bin_dir = module.params.get('bin_dir')
        if self.bin_dir is None:
            self.bin_dir =  module.get_bin_path('bin_dir', True)

        # Passed in arguments to the module
        self.name = module.params.get('name')
        self.namespace = module.params.get('namespace')
        self.chart_src = module.params.get('chart_src')
        self.chart_version = module.params.get('chart_version')
        self.path_to_values = module.params.get('path_to_values')
        self.state = module.params.get('state')
        self.atomic = module.params.get('atomic')

        # Format the commands
        self.kubectl_cmd = ['{}/kubectl'.format(self.bin_dir)]
        self.helm_cmd = ['{}/helm'.format(self.bin_dir)]


    # Runs the commands after joining them and also handles failing commands.
    # Returns result text and a bool representing if the command succeeded.
    def _execute(self, cmd, use_unsafe_shell=False):
        try:
            rc, out, err = self.module.run_command(' '.join(cmd), use_unsafe_shell=use_unsafe_shell)
            if rc != 0:
                self.module.fail_json(
                    msg="error running ({}) command (rc={}), out='{}', err='{}'".format(' '.join(cmd), rc, out, err))
        except Exception as exc:
            self.module.fail_json(
                msg='error running ({}) command: {}'.format(' '.join(cmd), str(exc)))
        return out, rc == 0


    def _execute_nofail(self, cmd):
        rc, out, err = self.module.run_command(' '.join(cmd))
        if rc != 0:
            return err
        return out
        

    def fetch_and_apply_chart(self):
        # helm template with values.yml

        result, success = self.create_namespace()

        if not success:
        # we couldn't create the namespace for some reason
            return result, success

        # Get all release names
        chart_check_cmd = self.helm_cmd[:]
        chart_check_cmd.append('list')
        chart_check_cmd.append('--short')
        # 'helm3 list' is namespaced where 'helm2 list' was not. Alter this check
        if self.is_helm_3():
            chart_check_cmd.append('--namespace')
            chart_check_cmd.append(self.namespace)
        result, __ = self._execute(chart_check_cmd)

        # Does the release name already exist?
        if self.name in result:
        # already deployed

            if self.state == 'latest':    # upgrade chart
                return self.upgrade_chart()

            elif self.state == 'absent': # it exists and we don't want it to
                return self.delete_chart()
            
            else:
                return "Release already exists, not upgrading. Use state: 'latest' parameter to override.", "skip"


        elif self.state == 'present' or self.state == 'latest':
        # not deployed, install it
            return self.install_chart()

        else:
            return "Nothing to be done", "skip"


    def is_helm_3(self):
        helm_version_cmd = self.helm_cmd[:]
        helm_version_cmd.append('version')

        # run 'helm version'
        results, success = self._execute(helm_version_cmd)
        # make a regex matching v2.1.1 or some variation. Get the first match
        exp = compile("v\d*\.\d*\.\d*")
        reg_result = findall(exp, results)
        # if didn't find any matches, something is wrong with helm.
        if len(reg_result) == 0:
            self.module.fail_json(msg='Could not find helm version string')
            raise RuntimeError("Could not find helm version string")

        reg_result = reg_result[0]

        # reg_result is something like 'v3.X.X' or 'v2.X.X'
        # If the second char is 3 or greater we are using helm v3
        return int(reg_result[1]) >= 3


    def create_namespace(self):
        # Don't make a namespace if it exists already
        if self.namespace:
            ns_check_cmd = self.kubectl_cmd[:]
            ns_check_cmd.append('get')
            ns_check_cmd.append('namespace')
            ns_check_cmd.append(self.namespace)

            if 'not found' in self._execute_nofail(ns_check_cmd):
                ns_create_cmd = self.kubectl_cmd[:]
                ns_create_cmd.append('create')
                ns_create_cmd.append('namespace')
                ns_create_cmd.append(self.namespace)

                result, success = self._execute(ns_create_cmd)
                return result, success

            return "No namespace made", True


    def upgrade_chart(self):
        # run helm upgrade

        chart_upgrade_cmd = self.helm_cmd[:]
        chart_upgrade_cmd.append('upgrade')
        chart_upgrade_cmd.append(self.name)
        chart_upgrade_cmd.append(self.chart_src)
        if self.atomic:
            chart_upgrade_cmd.append('--atomic')    # lets make sure deploy either worked or nothing changed

        if self.path_to_values:
            chart_upgrade_cmd.append('--values')
            chart_upgrade_cmd.append(self.path_to_values)

        if self.namespace:
            chart_upgrade_cmd.append('--namespace')
            chart_upgrade_cmd.append(self.namespace)

        if self.chart_version:
            chart_upgrade_cmd.append('--version')
            chart_upgrade_cmd.append(self.chart_version)

        return self._execute(chart_upgrade_cmd)


    def install_chart(self):
        # run helm install

        chart_install_cmd = self.helm_cmd[:]
        chart_install_cmd.append('install')
        # helm3 got rid of the --name option and rearranged the order of args
        if self.is_helm_3():
            chart_install_cmd.append(self.name)
            chart_install_cmd.append(self.chart_src)
        else:
            chart_install_cmd.append(self.chart_src)
            chart_install_cmd.append('--name')
            chart_install_cmd.append(self.name)

        if self.atomic:
            chart_install_cmd.append('--atomic')    # lets make sure deploy either worked or nothing changed

        if self.path_to_values:
            chart_install_cmd.append('--values')
            chart_install_cmd.append(self.path_to_values)

        if self.namespace:
            chart_install_cmd.append('--namespace')
            chart_install_cmd.append(self.namespace)

        if self.chart_version:
            chart_install_cmd.append('--version')
            chart_install_cmd.append(self.chart_version)

        return self._execute(chart_install_cmd)


    def delete_chart(self):
        # run helm delete 

        chart_install_cmd = self.helm_cmd[:]
        chart_install_cmd.append('delete')
        chart_install_cmd.append(self.name)
        # helm3 delete is namespaced, and removes the --purge argument
        if self.is_helm_3():
            chart_install_cmd.append('--namespace')
            chart_install_cmd.append(self.namespace)
        else:
            chart_install_cmd.append('--purge')

        return self._execute(chart_install_cmd)

            
def main():

    module = AnsibleModule(
        argument_spec =
        {
            'name': {'required': True, 'type': 'str'},
            'namespace': {'required': False, 'type': 'str'},
            'chart_src': {'required': True, 'type': 'str'},
            'chart_version': {'required': True, 'type': 'str'},
            'path_to_values': {'required': False, 'type': 'str'},
            'state': {'default': 'present', 'type': 'str'},
            'atomic': {'default': False, 'type': 'bool'},
            'bin_dir': {'required': True, 'type': 'str'}
        }
    )

    manager = KubeManager(module)

    result, changed = manager.fetch_and_apply_chart()

    # Changed can be either true, false, or "skip". Once we know its not a string
    # we know its a boolean, so we can use its value as a boolean like in "changed".
    # Meanwhile the expression next to "skipped" will handle converting it to a 
    # boolean if its a string.
    module.exit_json(changed = changed if changed != "skip" else False,
                     skipped = True if changed == "skip" else False,
                     msg='success: {}'.format(result)
                     )


from ansible.module_utils.basic import *
if __name__ == '__main__':
    main()