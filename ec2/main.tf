resource "aws_instance" "vm" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids
  key_name                    = var.key_name
  vpc_security_group_ids      = var.vpc_security_group_ids
  user_data                   = var.enable_user_data ? var.user_data : null
  user_data_replace_on_change = var.user_data_replace_on_change 
  tags                        = merge({ "Name" = var.name }, var.instance_tags, var.tags)
  volume_tags                 = var.enable_volume_tags ? merge({ "Name" = var.name }, var.volume_tags) : null
}