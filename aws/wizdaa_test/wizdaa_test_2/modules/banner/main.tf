variable "message" { 
    type = string 
    
}


resource "local_file" "banner" {
  filename = "./banner_${terraform.workspace}.txt"
  content  = var.message
}


output "banner_path" { 
    value = local_file.banner.filename 
}