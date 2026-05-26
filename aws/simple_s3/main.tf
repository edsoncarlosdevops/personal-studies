module "meu_bucket" {
    source = "./modules"
    environment = "dev"
    sufixo = "edson" # Troque por algo único seu
}