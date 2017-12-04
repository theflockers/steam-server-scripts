/* this remote state */
terraform {
    backend "s3" {
        bucket  = "remote-states"
        encrypt = "true"
        key     = "steam/server.state"
    }
}
