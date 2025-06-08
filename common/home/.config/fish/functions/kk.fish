function kk --wraps='kubectl --kubeconfig ~/.kind-kube/config' --description 'alias kk=kubectl --kubeconfig ~/.kind-kube/config'
  kubectl --kubeconfig ~/.kind-kube/config $argv; 
end
