{
	config,
	lib,
	...
	}:
	with lib
	with config.dots.info.host.interface.boot
	{
		config.boot = {
		inherit timeout
	}
}
