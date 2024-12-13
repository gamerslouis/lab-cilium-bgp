KUBECONFIG := $(HOME)/.kube/config

default: clab cilium wait-for-cilium bgp status

clab:
	containerlab -d --log-level debug deploy -t topo.yaml
	kind export kubeconfig --name=clab-bgp-cplane-demo

cilium:
	cilium install --version=1.16.4 \
	  --set routingMode=native \
	  --set ipv4NativeRoutingCIDR="10.0.0.0/8" \
	  --set bgpControlPlane.enabled=true \
	  --set ipam.mode=kubernetes \
	  --set k8s.requireIPv4PodCIDR=true

wait-for-cilium:
	cilium status --wait

bgp:
	kubectl apply -f cilium-bgp-cluster-config.yaml

status:
	kubectl get pods -n kube-system

dump:
	cilium bgp peers
	cilium bgp routes available ipv4 unicast
	docker exec -it clab-bgp-cplane-demo-router0 vtysh -c 'show ip bgp summary'
	docker exec -it clab-bgp-cplane-demo-router0 vtysh -c 'show ip route'

clean:
	containerlab destroy -t topo.yaml
