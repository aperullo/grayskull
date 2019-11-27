# RKE with custom certs

If you want to provide custom certs follow these steps.

3.  `ansible-playbook -i inventory/rancher.ini playbooks/ranch_prepare_gray.yml`. This will create the certs necessary if we later want to join to a rancher server. It overrides the default kubernetes certs.
4. `rke up --config inventory/rke_gray.yml --cert-dir playbooks/certs/csr --custom-certs`. This will start the deploy process.