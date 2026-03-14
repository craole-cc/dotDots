{
  powerdevil = {
    AC = {
      powerButtonAction = "lockScreen";
      autoSuspend = {
        action = "shutDown";
        idleTimeout = 1000;
      };
      turnOffDisplay = {
        idleTimeout = 1000;
        idleTimeoutWhenLocked = "immediately";
      };
    };
    battery = {
      powerButtonAction = "sleep";
      whenSleepingEnter = "standbyThenHibernate";
    };
    lowBattery = {
      whenLaptopLidClosed = "hibernate";
    };
  };
}
