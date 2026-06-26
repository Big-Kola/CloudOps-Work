resource "random_id" "example" {
  byte_length = 4
}

resource "local_file" "shared" {
  filename = "${path.module}/shared-config.txt"
  content  = "This is shared state data"
}