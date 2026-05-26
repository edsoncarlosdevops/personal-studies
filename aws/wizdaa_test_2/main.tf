#Goal: Show module use and workspace-aware filenames without changing code.
terraform { 
    required_providers { 
        local = { 
            source = "hashicorp/local" 
            
        } 
        
    } 
    
}

module "b" {
  source  = "./modules/banner"
  message = "hello from ${terraform.workspace}"
}

output "path" { 
    value = module.b.banner_path 
}