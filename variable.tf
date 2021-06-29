variable access_key {
 type = string
}

variable secret_key {
 type = string
}

variable region {
 type = string
}

variable vpc_name {
 type = list
 default = ["kubernetes-vpc"]
}

variable ssh_cidr {
 type = list
}

variable pub_subnet_name {
 type = list
}

variable prv_subnet_name {
 type = list
}

variable nsg_name {
 type = string
}

variable pub_box_count {
 type = number
}

variable pub_instance_type {
 type = string
}

variable pub_instance_name {
 type = string
}

variable prv_main_box_count {
 type = number
}

variable prv_instance_type {
 type = string
}

variable prv_main_instance_name {
 type = string
}

variable prv_box_count {
 type = number
}

variable prv_instance_name {
 type = string
}
