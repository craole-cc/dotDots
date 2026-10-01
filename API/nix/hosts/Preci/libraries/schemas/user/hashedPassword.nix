{...}: {
  default = null;

  resolve = {args ? {}}:
    args.hashedPassword or null;
}
