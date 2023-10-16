
resource "aws_efs_access_point" "prometheus_server_efs" {
 file_system_id = aws_efs_file_system.efs.id
 root_directory {
   path = "/prometheus_server"
 }
}

resource "aws_efs_access_point" "prometheus_alertmanager_efs" {
 file_system_id = aws_efs_file_system.efs.id
 root_directory {
   path = "/prometheus_alertmanager"
 }
}



resource "helm_release" "prometheus" {
  name      = "prometheus"
  namespace = "default"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  values = [
    <<EOF
server:
  persistentVolume: 
    storageClass: "efs-ap-sc"
EOF
  ]

  depends_on = [aws_eks_cluster.eks_cluster]
}


resource "helm_release" "grafana" {
  name      = "grafana"
  namespace = "default"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  #  set {
  #    name  = "service.loadBalancerIP"
  #    value = "192.169.7.197"
  #  }

  depends_on = [aws_eks_cluster.eks_cluster]
}
