# resource "kubernetes_deployment" "network_test" {
#   metadata {
#     name = "network-test"
#   }
#
#   spec {
#     replicas = 1
#
#     selector {
#       match_labels = {
#         app = "network-test"
#       }
#     }
#
#     template {
#       metadata {
#         labels = {
#           app = "network-test"
#         }
#       }
#
#       spec {
#         container {
#           name  = "network-test-container"
#           image = "hashicorp/http-echo"
#           args  = ["-text=Hello, World!"]
#           port {
#             container_port = 5678
#           }
#         }
#       }
#     }
#   }
# }
#
# resource "kubernetes_service" "network_test_service" {
#   metadata {
#     name = "network-test-service"
# annotations = {
#   "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
#   # "service.beta.kubernetes.io/aws-load-balancer-private-ipv4-addresses" = "52.52.21.250"
#   # "service.beta.kubernetes.io/aws-load-balancer-internal" = "true"
#   # "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "tcp"
#   # "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
#   "service.beta.kubernetes.io/aws-load-balancer-eip-allocations" = aws_eip.sb_dev.id
#   "service.beta.kubernetes.io/aws-load-balancer-subnets" = aws_subnet.wp_subnet_1.id
# }
#   }
#
#   spec {
#     # type = "LoadBalancer"
#
#     selector = {
#       app = "network-test"
#     }
#
#     port {
#       protocol    = "TCP"
#       port        = 80
#       target_port = 5678
#     }
#   }
#
#   depends_on = [aws_eks_cluster.eks_cluster]
# }



