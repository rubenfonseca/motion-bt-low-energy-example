class MainViewController < UITableViewController
  attr_accessor :start_button, :stop_button
  attr_accessor :manager
  attr_accessor :peripherals

  def init
    super.tap do |i|
      i.manager     = CBCentralManager.alloc.initWithDelegate self, queue:nil
      i.peripherals = []
    end

    self
  end
  
  def viewDidLoad
    super

    self.title = "Bluetooth LE"

    self.start_button = UIBarButtonItem.alloc.initWithTitle "Start", style:UIBarButtonItemStyleBordered, target:self, action:"startButtonClicked:"
    self.stop_button  = UIBarButtonItem.alloc.initWithTitle "Stop", style:UIBarButtonItemStyleDone, target:self, action:"stopButtonClicked:"

    self.navigationItem.rightBarButtonItem = self.start_button
  end

  def startButtonClicked(sender)
    self.navigationItem.rightBarButtonItem = self.stop_button

    # Search for hearth rate monitors
    uuid = CBUUID.UUIDWithString "180D"
    manager.scanForPeripheralsWithServices [uuid], options:nil
  end

  def stopButtonClicked(sender)
    self.navigationItem.rightBarButtonItem = self.start_button

    manager.stopScan
  end

  # UITableView Data Source
  def numberOfSectionsInTableView(tableview)
    1
  end

  def tableView(tableview, numberOfRowsInSection:section)
    peripherals.count
  end

  CELL_IDENTIFIER = "Cell Identifier"
  def tableView(tableview, cellForRowAtIndexPath:indexPath)
    peripheral = peripherals[indexPath.row]

    cell = tableview.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) || begin
      r = UITableViewCell.alloc.initWithStyle UITableViewCellStyleSubtitle, reuseIdentifier:CELL_IDENTIFIER
      r
    end

    cell.textLabel.text = peripheral.name
    cell.detailTextLabel.text = CFUUIDCreateString(nil, peripheral.UUID)
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator

    cell
  end

  def tableView(tableview, didSelectRowAtIndexPath:indexPath)
    tableview.deselectRowAtIndexPath(indexPath, animated:true)
    
    peripheral = peripherals[indexPath.row]
    peripheral_vc = PeripheralViewController.alloc.initWithPeripheral(peripheral)
    navigationController.pushViewController peripheral_vc, animated:true

    self.stopButtonClicked nil
  end

  # CBCentralManagerDelegate
  def centralManagerDidUpdateState(state)
    state = nil;

    case @manager.state
    when CBCentralManagerStateUnsupported
      state = "The platform/hardware doesn't support BLE"
    when CBCentralManagerStateUnauthorized
      state = "The app is not authorized to use BLE"
    when CBCentralManagerStatePoweredOff
      state = "BLE is currently powered off"
    else
      return false
    end

    NSLog "Central manager state: %@", state

    alert = UIAlertView.alloc.initWithTitle "Bluetooth status",
                              message: state,
                              delegate: nil,
                              cancelButtonTitle: "Dismiss",
                              otherButtonTitles: nil
    alert.show

    return false
  end

  def centralManager(manager, didDiscoverPeripheral:peripheral, advertisementData:data, RSSI:rssi)
    NSLog "didDiscoverPeripheral %@ %@ %@", peripheral, data, rssi

    unless peripherals.containsObject(peripheral)
      peripherals << peripheral

      tableView.reloadData
    end

    manager.connectPeripheral peripheral, options:nil
  end
  
end

