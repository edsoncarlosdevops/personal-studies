# main.tf (blank-ish starter)
#Goal: Use random_pet and local_file to generate two names and write them to a file.

terraform {
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
    local  = { source = "hashicorp/local",  version = "~> 2.5" }
  }
}

variable "prefix" { 
    type = string
 }

resource "random_pet" "a" { 
    prefix = var.prefix
    
}
resource "random_pet" "b" { 
    prefix = var.prefix 
    
}

resource "local_file" "team" {
  filename = "./team.txt"
  content  = "${random_pet.a.id}\n${random_pet.b.id}\n"
}

output "file_path" { value = local_file.team.filename }
output "team_names" { value = [random_pet.a.id, random_pet.b.id] }