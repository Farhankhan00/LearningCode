resource "tls_private_key" "tsa_host_key" {
  algorithm   = "RSA"
  rsa_bits    = "4096"
}

resource "tls_private_key" "session_signing_key" {
  algorithm   = "RSA"
  rsa_bits    = "4096"
}

resource "tls_private_key" "tsa_worker_key" {
  algorithm   = "RSA"
  rsa_bits    = "4096"
} 

resource "aws_ssm_parameter" "tsa_host_privatekey" {
  name  = "/concourse/tsa-host-privatekey"
  type  = "SecureString"
  value = "${tls_private_key.tsa_host_key.private_key_pem}"
}

resource "aws_ssm_parameter" "tsa_host_publickey" {
  name  = "/concourse/tsa-host-publickey"
  type  = "SecureString"
  value = "${tls_private_key.tsa_host_key.public_key_pem}"
}

resource "aws_ssm_parameter" "session_signing_key_privatekey" {
  name  = "/concourse/session_signing_key-privatekey"
  type  = "SecureString"
  value = "${tls_private_key.session_signing_key.private_key_pem}"
}


resource "aws_ssm_parameter" "session_signing_key_publickey" {
  name  = "/concourse/session_signing_key-publickey"
  type  = "SecureString"
  value = "${tls_private_key.session_signing_key.public_key_pem}"
}

resource "aws_ssm_parameter" "tsa_worker_privatekey" {
  name  = "/concourse/tsa-worker-privatekey"
  type  = "SecureString"
  value = "${tls_private_key.tsa_worker_key.private_key_pem}"
}

resource "aws_ssm_parameter" "tsa_worker_publickey" {
  name  = "/concourse/tsa-worker-publickey"
  type  = "SecureString"
  value = "${tls_private_key.tsa_worker_key.public_key_pem}"
}