$numberOfColumns = 0
$numberOfFloors = 0 
$numberOfElevators = 0
$waitingTime = 0         
$maxWeight = 0           


# ------------------------------------------- COLUMN CLASS ------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------------------
class Column
    #  ------------------ Constructor and its attributes ------------------
    attr_accessor :id, :status, :numberOfFloors, :numberOfElevators, :elevatorsList, :buttonsUpList, :buttonsDownList
    def initialize(id, columnStatus, numberOfFloors, numberOfElevators)
        @id = id
        @status = columnStatus
        @numberOfFloors = numberOfFloors
        @numberOfElevators = numberOfElevators
        @elevatorsList = []
        @buttonsUpList = []
        @buttonsDownList = []

        createElevatorsList
        createButtonsUpList
        createButtonsDownList    
    end

    def display
        puts "Created column #{@id}"
        puts "Number of floors: #{@numberOfFloors}"
        puts "Created Number of elevators: #{@numberOfElevators}"
        puts "----------------------------------"
    end


    def createElevatorsList
        for x in 1..@numberOfElevators do
            @elevatorsList.append(Elevator.new(x, @numberOfFloors, 1, ElevatorStatus::IDLE, SensorStatus::OFF, SensorStatus::OFF))

        end
    end

    def createButtonsUpList
        for x in 1..(@numberOfFloors - 1) do
            @buttonsUpList.append(Button.new(x, ButtonStatus::OFF, x))

        end
    end


    def createButtonsDownList
        for x in 2..@numberOfFloors do
            @buttonsDownList.append(Button.new(x, ButtonStatus::OFF, x))

        end
    end

    def findElevator(currentFloor, direction)
        activeElevatorList = []
        idleElevatorList = []
        sameDirectionElevatorList = []
        for x in @elevatorsList
            if x.status != ElevatorStatus::IDLE #verify if elevator is active and if the request is on the elevator way
                if x.status == ElevatorStatus::UP and x.floor <= currentFloor or x.status == ElevatorStatus::DOWN and x.floor >= currentFloor
                    activeElevatorList.append(x)
                end
            else
                idleElevatorList.append(x)
            end
        end

        if activeElevatorList.length > 0 #Create new list for elevators with same direction that the request
            sameDirectionElevatorList = activeElevatorList.select {|elevator| elevator.status == direction}
        end
        
        if sameDirectionElevatorList.length > 0
            bestElevator = findNearestElevator(currentFloor, sameDirectionElevatorList)
        else
            bestElevator = findNearestElevator(currentFloor, idleElevatorList)
        end
            
    return bestElevator
    end

    # LOGIC TO FIND THE NEAREST ELEVATOR
    def findNearestElevator(currentFloor, selectedList)
        bestElevator = selectedList[0]
        bestDistance = (selectedList[0].floor - currentFloor).abs #abs() returns the absolute value of a number (always positive).
    
        for elevator in selectedList
            if (elevator.floor - currentFloor).abs < bestDistance
                bestElevator = elevator
            end
        end
        
        puts ""
        puts "   >> >>> ELEVATOR #{bestElevator.id} WAS CALLED <<< <<"
    return bestElevator
    end



    def requestElevator(requestedFloor, direction)
        if direction == ButtonDirection::UP
            @buttonsUpList[requestedFloor-1].status = ButtonStatus::ON
        else
            @buttonsDownList[requestedFloor-2].status = ButtonStatus::ON
        end

        puts ">> Someone request an elevator from floor <#{requestedFloor}> and direction <#{direction}> <<"
        for x in @elevatorsList do
            puts "Elevator#{x.id} | Floor: #{x.floor} | Status: #{x.status}"
        end

        bestElevator = findElevator(requestedFloor, direction)
        bestElevator.addFloorToFloorList(requestedFloor) 
        bestElevator.moveElevator(requestedFloor, self)
    end



end


class Elevator

    attr_accessor :id, :numberOfFloors, :floor, :status, :weightSensor, :obstructionSensor, :elevatorDoor, :elevatorDisplay, :floorDoorsList, :floorDisplaysList, :floorButtonsList, :floorList
    def initialize(id, numberOfFloors, floor, elevatorStatus, weightSensorStatus, obstructionSensorStatus)
        @id = id
        @numberOfFloors = numberOfFloors
        @floor = floor
        @status = elevatorStatus
        @weightSensor = weightSensorStatus
        @obstructionSensor = obstructionSensorStatus
        @elevatorDoor = Door.new(0, DoorStatus::CLOSED, 0)
        @elevatorDisplay = Display.new(0, DisplayStatus::ON, 0)
        @floorDoorsList = []
        @floorDisplaysList = []
        @floorButtonsList = []
        @floorList = []

        createFloorDoorsList
        createDisplaysList
        createFloorButtonsList
    end

    def createFloorDoorsList
        for x in 1..@numberOfFloors do
            @floorDoorsList.append(Door.new(x, DoorStatus::CLOSED, x))

        end
    end


    def createDisplaysList
        for x in 1..@numberOfFloors do
            @floorDisplaysList.append(Display.new(x, DisplayStatus::ON, x))

        end
    end

    def createFloorButtonsList
        for x in 1..@numberOfFloors do
            @floorButtonsList.append(Button.new(x, ButtonStatus::ON, x))

        end
    end

    def moveElevator(requestedFloor, requestedColumn)
        while @floorList.length() != 0
            if @status == ElevatorStatus::IDLE
                if @floor < requestedFloor
                    @status = ElevatorStatus::UP
                elsif @floor == requestedFloor
                    openDoors($waitingTime)
                    deleteFloorFromList(requestedFloor)
                    requestedColumn.buttonsUpList[requestedFloor-1].status = ButtonStatus::OFF
                    requestedColumn.buttonsDownList[requestedFloor-1].status = ButtonStatus::OFF
                    @floorButtonsList[requestedFloor-1].status = ButtonStatus::OFF
                else
                    @status = ElevatorStatus::DOWN
                end
            end

            if @status == ElevatorStatus::UP
                moveUp(requestedColumn)
            else
                moveDown(requestedColumn)
            end

        end
    end

    def moveUp(requestedColumn)
        tempArray = @floorList.dup
        for x in @floor..(tempArray[tempArray.length - 1] - 1)
            if @floorDoorsList[x].status == DoorStatus::OPENED or @elevatorDoor.status == DoorStatus::OPENED
                puts "   Doors are open, closing doors before move up"
                closeDoors
            end
            
            puts "Moving elevator#{(@id)} <up> from floor #{x} to floor #{x + 1}"
            nextFloor = (x + 1)
            @floor = nextFloor
            updateDisplays(@floor)
            
            if tempArray.include? nextFloor
                openDoors($waitingTime)
                deleteFloorFromList(nextFloor)
                requestedColumn.buttonsUpList[x - 1].status = ButtonStatus::OFF
                floorButtonsList[x].status = ButtonStatus::OFF
            end
        end
            
        if @floorList.length() == 0
            @status = ElevatorStatus::IDLE

        else
            @status = ElevatorStatus::DOWN
            puts "       Elevator#{@id} is now going #{@status}"
        end
    end


    def moveDown(requestedColumn)
        tempArray = @floorList.dup
        for x in @floor.downto(tempArray[tempArray.length - 1] + 1)
            if @floorDoorsList[x - 1].status == DoorStatus::OPENED or @elevatorDoor.status == DoorStatus::OPENED
                puts "   Doors are open, closing doors before move down"
                closeDoors
            end
            
            puts "Moving elevator#{(@id)} <down> from floor #{x} to floor #{x - 1}"
            nextFloor = (x - 1)
            @floor = nextFloor
            updateDisplays(@floor)
            
            if tempArray.include? nextFloor
                openDoors($waitingTime)
                deleteFloorFromList(nextFloor)
                requestedColumn.buttonsUpList[x - 2].status = ButtonStatus::OFF
                floorButtonsList[x - 1].status = ButtonStatus::OFF
            end
        end
            
        if @floorList.length() == 0
            @status = ElevatorStatus::IDLE

        else
            @status = ElevatorStatus::UP
            puts "       Elevator#{@id} is now going #{@status}"
        end
    end

    def updateDisplays(elevatorFloor)
        for display in @floorDisplaysList
            display.floor = elevatorFloor
        end
        
        puts "Displays show ##{elevatorFloor}"
    end

    def openDoors(waitingTime)
        puts "       Opening doors..."
        puts "       Elevator#{@id} doors are opened"
        @elevatorDoor.status = DoorStatus::OPENED
        @floorDoorsList[@floor-1].status = DoorStatus::OPENED
        sleep(waitingTime)
        closeDoors
    end

    def closeDoors
        if @weightSensor == SensorStatus::OFF and @obstructionSensor == SensorStatus::OFF
            puts "       Closing doors..."
            puts "       Elevator#{@id} doors are closed"
            @floorDoorsList[@floor-1].status = DoorStatus::CLOSED
            @elevatorDoor.status = DoorStatus::CLOSED
        end
    end

    def checkWeight(maxWeight)
        weight = rand(1..600)
        while weight > maxWeight
            @weightSensor = SensorStatus::ON
            puts "       ! Elevator capacity reached, waiting until the weight is lower before continue..."
            weight -= 100 
        end

        @weightSensor = SensorStatus::OFF
        puts "       Elevator capacity is OK"
    end


    def checkObstruction
        probabilityNotBlocked = 70
        number = rand(1..100) 

        while number > probabilityNotBlocked
            @obstructionSensor = SensorStatus::ON
            puts "       ! Elevator door is blocked by something, waiting until door is free before continue..."
            number -= 30 
        end

        @obstructionSensor = SensorStatus::OFF
        puts "       Elevator door is FREE"
    end


    def addFloorToFloorList(floor)
        @floorList.append(floor)
        puts "Elevator#{@id} - floor #{floor} added to floorList"
    end


    def deleteFloorFromList(stopFloor)
        index = @floorList.find_index(stopFloor)
        if index > -1
            @floorList.delete_at(index)
        end
    end


    def requestFloor(requestedFloor, requestedColumn)
        puts ""          
        puts ">> Someone inside the elevator#{@id} wants to go to floor <#{requestedFloor}> <<"
        checkWeight($maxWeight)
        checkObstruction()
        addFloorToFloorList(requestedFloor)
        moveElevator(requestedFloor, requestedColumn)
    end

end

class Door
    attr_accessor :id, :status, :floor
    def initialize(id, doorStatus, floor)
        @id = id
        @status = doorStatus
        @floor = floor
    end
end


class Button
    attr_accessor :id, :status, :floor
    def initialize(id, buttonStatus, floor)
        @id = id
        @status = buttonStatus
        @floor = floor
    end
end

class Display
    attr_accessor :id, :status, :floor
    def initialize(id, displayStatus, floor)
        @id = id
        @status = displayStatus
        @floor = floor
    end
end

module ColumnStatus
    ACTIVE = "active"
    INACTIVE = 'inactive'
end


module ElevatorStatus
    IDLE = 'idle'
    UP = 'up'
    DOWN = 'down'
end


module ButtonDirection
    UP = 'up'
    DOWN = 'down'
end

module ButtonStatus
    ON = 'on'
    OFF = 'off'
end

module SensorStatus
    ON = 'on'
    OFF = 'off'
end

module DoorStatus
    OPENED = 'opened'
    CLOSED = 'closed'
end

module DisplayStatus
    ON = 'on'
    OFF = 'off'
end


# ------------------------------------------- TESTING PROGRAM ------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------------------
$waitingTime = 1 
$maxWeight = 500 

# ******* CREATE SCENARIO 1 ******* 
def self.scenario1()
    puts ""
    puts "****************************** SCENARIO 1: ******************************"
    columnScenario1 = Column.new(1, ColumnStatus::ACTIVE, 10, 2) 
    columnScenario1.display()  
    columnScenario1.elevatorsList[0].floor = 2 
    columnScenario1.elevatorsList[1].floor = 6 
    
    puts ""
    puts "Person 1: (elevator 1 is expected)"
    columnScenario1.requestElevator(3, ButtonDirection::UP) 
    columnScenario1.elevatorsList[0].requestFloor(7, columnScenario1) 
    puts "=================================="
end

# ******* CREATE SCENARIO 2 ******* 
def self.scenario2()
    puts ""
    puts "****************************** SCENARIO 2: ******************************"
    columnScenario2 = Column.new(1, ColumnStatus::ACTIVE, 10, 2) 
    columnScenario2.display()  
    columnScenario2.elevatorsList[0].floor = 10 
    columnScenario2.elevatorsList[1].floor = 3 
    
    puts ""
    puts "Person 1: (elevator 2 is expected)"
    columnScenario2.requestElevator(1, ButtonDirection::UP) 
    columnScenario2.elevatorsList[1].requestFloor(6, columnScenario2) 
    puts "----------------------------------"
    puts ""
    puts "Person 2: (elevator 2 is expected)"
    columnScenario2.requestElevator(3, ButtonDirection::UP) 
    columnScenario2.elevatorsList[1].requestFloor(5, columnScenario2) 
    puts "----------------------------------"
    puts ""
    puts "Person 3: (elevator 1 is expected)"
    columnScenario2.requestElevator(9, ButtonDirection::DOWN) 
    columnScenario2.elevatorsList[0].requestFloor(2, columnScenario2) 
    puts "=================================="
end

# ******* CREATE SCENARIO 3 ******* 
def self.scenario3()
    puts ""
    puts "****************************** SCENARIO 3: ******************************"
    columnScenario3 = Column.new(1, ColumnStatus::ACTIVE, 10, 2) 
    columnScenario3.display()  
    columnScenario3.elevatorsList[0].floor = 10 
    columnScenario3.elevatorsList[1].floor = 3 
    columnScenario3.elevatorsList[1].status = ElevatorStatus::UP 


    puts ""
    puts "Person 1: (elevator 1 is expected)"
    columnScenario3.requestElevator(3, ButtonDirection::DOWN) 
    columnScenario3.elevatorsList[0].requestFloor(2, columnScenario3) 
    puts "----------------------------------"
    puts ""

    # 2 minutes later elevator 1(B) finished its trip to 6th floor
    columnScenario3.elevatorsList[1].floor = 6
    columnScenario3.elevatorsList[1].status = ElevatorStatus::IDLE

    puts "Person 2: (elevator 2 is expected)"
    columnScenario3.requestElevator(10, ButtonDirection::DOWN) 
    columnScenario3.elevatorsList[1].requestFloor(3, columnScenario3) 
    puts ("==================================")
end


''' -------- CALL SCENARIOS -------- '''
#ResidentialController::scenario1
#ResidentialController::scenario2
#ResidentialController::scenario3
