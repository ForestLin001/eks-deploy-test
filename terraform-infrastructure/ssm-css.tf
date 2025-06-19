# 定义 ClusterSecretStore
resource "kubernetes_manifest" "aws_ssm_cluster_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = var.cluster_secret_store_name
    }
    spec = {
      provider = {
        aws = {
          service = "ParameterStore"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = kubernetes_service_account.external_secrets_sa.metadata[0].name
                namespace = kubernetes_service_account.external_secrets_sa.metadata[0].namespace
              }
            }
          }
        }
      }
    }
  }
  # Ensure the Service Account is created before the ClusterSecretStore
  depends_on = [
    kubernetes_service_account.external_secrets_sa,
    helm_release.external_secrets_operator,
    null_resource.wait_for_crd
  ]
}