resource "aws_iam_user" "test_user" {
  name = "test_user"
}

resource "aws_iam_policy" "policy" {
  name        = "test_user-policy"
  description = "My test policy"

  policy = "${file("roles.json")}"
}
