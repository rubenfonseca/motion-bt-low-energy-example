class PeripheralViewController < UITableViewController
  attr_accessor :peripheral
  attr_accessor :heart_rate, :sensor_location, :device_name, :device_manufacturer

  def initWithPeripheral(p)
    init.tap do |i|
      i.peripheral = p
    end
  end

  def viewDidLoad
    super

    self.title = peripheral.name

    peripheral.delegate = self
    peripheral.discoverServices nil
  end

  def dealloc
    peripheral.delegate = nil
  end

  # UITableViewDataSource
  def numberOfSectionsInTableView(tableview)
    1
  end

  HEART_RATE_ROW = 0
  SENSOR_LOCATION_ROW = 1
  DEVICE_NAME_ROW = 2
  DEVICE_MANUFACTER_ROW = 3

  def tableView(tableview, numberOfRowsInSection:section)
    4
  end

  INFO_CELL = "Info Cell"
  def tableView(tableview, cellForRowAtIndexPath:indexPath)
    cell = tableview.dequeueReusableCellWithIdentifier(INFO_CELL) || begin
      r = UITableViewCell.alloc.initWithStyle UITableViewCellStyleSubtitle, reuseIdentifier:INFO_CELL
      r
    end

    case indexPath.row
    when HEART_RATE_ROW
      cell.textLabel.text = "Heart Rate"
      cell.detailTextLabel.text = "#{self.heart_rate} BPM"
    when SENSOR_LOCATION_ROW
      cell.textLabel.text = "Sensor Location"
      cell.detailTextLabel.text = self.sensor_location
    when DEVICE_NAME_ROW
      cell.textLabel.text = "Device Name"
      cell.detailTextLabel.text = self.device_name
    when DEVICE_MANUFACTER_ROW
      cell.textLabel.text = "Device Manufacter"
      cell.detailTextLabel.text = self.device_manufacturer
    end

    cell
  end

  # CBPeripheralDelegate
  def peripheral(peripheral, didDiscoverServices:error)
    NSLog "didDiscoverServices: %@", error

    return if error || !peripheral.services

    peripheral.services.each do |service|
      NSLog "Service found with UUID: %@", service.UUID

      if service.UUID == CBUUID.UUIDWithString("180D")
        NSLog "-> FOUND service heart rate"
        peripheral.discoverCharacteristics nil, forService:service
      end

      if service.UUID == CBUUID.UUIDWithString("180A")
        NSLog "-> FOUND service device information"
        peripheral.discoverCharacteristics nil, forService:service
      end

      if service.UUID == CBUUID.UUIDWithString(CBUUIDGenericAccessProfileString)
        NSLog "-> FOUND service Generic Access Profile"
        peripheral.discoverCharacteristics nil, forService:service
      end
    end
  end

  def peripheral(peripheral, didDiscoverCharacteristicsForService:service, error:error)
    NSLog "didDiscoverCharacteristicsForService: %@ error %@", service, error

    if service.UUID == CBUUID.UUIDWithString("180D")
      service.characteristics.each do |char|
        if char.UUID == CBUUID.UUIDWithString("2A37")
          NSLog "Found a Heart Rate Measurement Characteristic"

          # Start notifying for new values
          peripheral.setNotifyValue(true, forCharacteristic:char)
        end

        if char.UUID == CBUUID.UUIDWithString("2A38")
          NSLog "Found a Body Sensor Location Characteristic"

          # Start reading sensor location
          peripheral.readValueForCharacteristic char
        end

        if char.UUID == CBUUID.UUIDWithString("2A39")
          value = Pointer.new(:uchar)
          value[0] = 1
          valData = NSData.dataWithBytes(value[0], length:8)

          # Write heart rate control point
          peripheral.writeValue valData, forCharacteristic:char, type:CBCharacteristicWriteWithResponse
        end
      end
    end

    if service.UUID == CBUUID.UUIDWithString(CBUUIDGenericAccessProfileString)
      service.characteristics.each do |char|
        if char.UUID == CBUUID.UUIDWithString(CBUUIDDeviceNameString)
          NSLog "Found a Device Name Characteristic"
          peripheral.readValueForCharacteristic char
        end
      end
    end

    if service.UUID == CBUUID.UUIDWithString("180A")
      service.characteristics.each do |char|
        if char.UUID == CBUUID.UUIDWithString("2A29")
          NSLog "Found a Device Manufactor Name"
          peripheral.readValueForCharacteristic char
        end
      end
    end
  end

  # Invoked upon completion of a "readValueForCharacteristic:" request, or on the reception of a notification
  def peripheral(peripheral, didUpdateValueForCharacteristic:char, error:error)
    if char.UUID == CBUUID.UUIDWithString("2A37")
      if char.value || !error
        reportData = char.value.bytes
        bpm = 0

        if reportData[0] & 0x01 == 0
          # uint8 BPM
          bpm = reportData[1]
        else
          # uint16 BPM
          bpm = CFSwapInt16LittleToHost(reportData[1])
        end

        self.heart_rate = bpm
        self.tableView.reloadRowsAtIndexPaths [NSIndexPath.indexPathForRow(HEART_RATE_ROW, inSection:0)], withRowAnimation:UITableViewRowAnimationAutomatic
      end
    end

    if char.UUID == CBUUID.UUIDWithString("2A38")
      dataPointer = char.value.bytes

      if dataPointer
        location = dataPointer[0]
        locationString = nil

        case location
        when 0
          locationString = "Other"
        when 1
          locationString = "Chest"
        when 2
          locationString = "Wrist"
        when 3
          locationString = "Finger"
        when 4
          locationString = "Hand"
        when 5
          locationString = "Ear Lobe"
        when 6
          locationString = "Foot"
        else
          locationString = "Reserved"
        end

        self.sensor_location = locationString
        self.tableView.reloadRowsAtIndexPaths [NSIndexPath.indexPathForRow(SENSOR_LOCATION_ROW, inSection:0)], withRowAnimation:UITableViewRowAnimationAutomatic
      end
    end

    if char.UUID == CBUUID.UUIDWithString(CBUUIDDeviceNameString)
      self.device_name = NSString.alloc.initWithData(char.value, encoding:NSUTF8StringEncoding)
      self.tableView.reloadRowsAtIndexPaths [NSIndexPath.indexPathForRow(DEVICE_NAME_ROW, inSection:0)], withRowAnimation:UITableViewRowAnimationAutomatic
    end

    if char.UUID == CBUUID.UUIDWithString("2A29")
      self.device_manufacturer = NSString.alloc.initWithData(char.value, encoding:NSUTF8StringEncoding)
      self.tableView.reloadRowsAtIndexPaths [NSIndexPath.indexPathForRow(DEVICE_MANUFACTER_ROW, inSection:0)], withRowAnimation:UITableViewRowAnimationAutomatic
    end
  end
end
