output "worker_script" {
    value = data.template_file.master_script.rendered
}