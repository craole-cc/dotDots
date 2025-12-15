{
  enable = true;
  settings = {
    alias = {
      br = "build --release";
      rr = "run --release";
      rq = "run --quiet";
      rp = "run --package";
      rrp = "run  --release --package";
      rqp = "run --quiet --package";
      wq = "watch --quiet --clear --exec";
      wrp = "wq rrp --";
      wqp = "watch --quiet --clear --exec rqp";
      lint = "clippy --all-targets --all-features -- -D warnings";
      wl = "watch --quiet --clear --exec lint";
    };
  };
}
