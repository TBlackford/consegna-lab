resource "aws_launch_configuration" "ec2" {
  name                 = "ecs-configuration"
  image_id                  = "${var.wordpress_ami}"
  #image_id                  = data.aws_ami.amazon_linux_2.id
  instance_type        = var.instance_type
  security_groups      = ["${aws_security_group.ecs.id}", "${aws_security_group.ec2_egress.id}"]
  # iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("~/id_ed25519.pub")
    timeout     = "4m"
  }

   user_data = <<-EOF
        #!/bin/bash
        yum install -y httpd
        systemctl enable httpd — now
        amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
        wget https://wordpress.org/latest.tar.gz
        tar -xzf latest.tar.gz
        cp -r wordpress/* /var/www/html/
        systemctl restart httpd

        mysql -h [endpoint_of_rds_instance] -P 3306 -u admin -p
  EOF

}

resource "aws_key_pair" "deployer" {
  key_name   = "aws_key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWcXtrzsyvoxPWzZo738Y3ntZ8nEgQ2p3l24ucSBkp1 thomas.a.r.paine@gmail.com"
}

resource "aws_autoscaling_group" "ec2" {
  depends_on           = ["aws_nat_gateway.nat_gw", "aws_subnet.private_subnet"]
  name                 = "ecs-autoscale"
  vpc_zone_identifier  = ["${aws_subnet.private_subnet.id}"]
  launch_configuration = "${aws_launch_configuration.ec2.name}"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  load_balancers       = ["${aws_elb.ec2.name}"]
}

resource "aws_elb" "ec2" {
  name               = "wordpress-elb"
  security_groups    = ["${aws_security_group.ecs.id}", "${aws_security_group.elb.id}"]
  subnets            = ["${aws_subnet.public_subnet.id}"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/wp-admin/install.php"
    interval            = 30
  }
}

resource "aws_db_instance" "wordpress_db" {
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name              = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

  allocated_storage     = 10
  max_allocated_storage = 100
}

