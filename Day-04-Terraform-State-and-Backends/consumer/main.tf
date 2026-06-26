data "terraform_remote_state" "producer" {
  backend = "local"
  config = {
    path = "../producer/producer.tfstate"
  }
}

resource "local_file" "from_state" {
  filename = "${path.module}/consumed-output.txt"
  content  = "Read from producer: ${data.terraform_remote_state.producer.outputs.shared_file_path}"
}