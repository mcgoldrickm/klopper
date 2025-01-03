{
  description = "raspberry-pi-nix example";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    home-manager = {
      url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, raspberry-pi-nix, home-manager }:
    let
      inherit (nixpkgs.lib) nixosSystem;
      basic-config = { pkgs, lib, ... }: {
        # bcm2711 for rpi 3, 3+, 4, zero 2 w
        # bcm2712 for rpi 5
        # See the docs at:
        # https://www.raspberrypi.com/documentation/computers/linux_kernel.html#native-build-configuration
        raspberry-pi-nix.board = "bcm2711";
        time.timeZone = "Europe/London";

        # Select internationalisation properties.
        i18n.defaultLocale = "en_GB.UTF-8";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = "en_GB.UTF-8";
          LC_IDENTIFICATION = "en_GB.UTF-8";
          LC_MEASUREMENT = "en_GB.UTF-8";
          LC_MONETARY = "en_GB.UTF-8";
          LC_NAME = "en_GB.UTF-8";
          LC_NUMERIC = "en_GB.UTF-8";
          LC_PAPER = "en_GB.UTF-8";
          LC_TELEPHONE = "en_GB.UTF-8";
          LC_TIME = "en_GB.UTF-8";
        };

        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        nixpkgs.config.allowUnfree = true;

        environment.systemPackages = with pkgs; [
	  libraspberrypi
          neovim
	  zsh
	  fish
	  git
	  pciutils
	  lshw
	  exfat
	  klipper
	  mainsail
	  moonraker
	  can-utils
        ];

        programs.fish.enable = true;
	services.sshd.enable = true;


        console.keyMap = "uk";

        users.users.root.initialPassword = "root";
        users.users.mcgoldrickm = {
          isNormalUser = true;
          description = "Michael McGoldrick";
          extraGroups = ["networkmanager" "wheel" "video"];
          shell = pkgs.fish;
        };

        networking = {
          hostName = "klopper";
          useDHCP = false;
	  firewall.allowedTCPPorts = [ 80 7125 ];
        };

	systemd.network.enable = true;

	systemd.network.networks."10-lan" = {
          matchConfig.Name = "end0";
          networkConfig.DHCP = "ipv4";
        };

	systemd.network.networks."20-can" = {
	  matchConfig.Name = "can0";
	  canConfig.BitRate = 1000000;
	};

  # Enable mDNS so that our printer is adressable under http://nixprinter.local
        services.avahi = {
          enable = true;
          publish = {
            enable = true;
            addresses = true;
            workstation = true;
          };
        };

        services.moonraker = {
          user = "root";
          enable = true;
          address = "0.0.0.0";
          settings = {
            octoprint_compat = { };
            history = { };
            authorization = {
              force_logins = true;
              cors_domains = [
                 "*.local"
                 "*.lan"
                 "*://app.fluidd.xyz"
                 "*://my.mainsail.xyz"
              ];
              trusted_clients = [
                "10.0.0.0/8"
                "127.0.0.0/8"
                "169.254.0.0/16"
                "172.16.0.0/12"
                "192.168.1.0/24"
                "FE80::/10"
                "::1/128"
              ];
            };
          };
        };

        #services.fluidd.enable = true;
	services.mainsail.enable = true;
	services.klipper = {
	  enable = true;
	  #firmwares = {
	  #  mcu = {
	  #    enable = true;
          #    configFile = btt-octopus.config;
	  #    serial = "/dev/serial/by-id/usb-Klipper_stm32f446xx_180018000550335331383820-if00";
          #  };
	  #  mcu = {
	  #    enable = true;
	  #    configFile = ebb-can.config;
	  #    canbus_uuid = "8ca6634bd4c1";
	  #  };
	  #};
	  settings = {
            printer = {
  	      kinematics = "corexy";
              max_velocity = 300;  
              max_accel = 3000;             #Max 4000
              max_z_velocity = 15;          #Max 15 for 12V TMC Drivers, can increase for 24V
              max_z_accel = 350;
              square_corner_velocity = 5.0;
	    };
	    mcu = {
              serial = "/dev/serial/by-id/usb-Klipper_stm32f446xx_180018000550335331383820-if00";
              restart_method = "command";
	    };
	    "mcu EBBCan" = {
              canbus_uuid = "8ca6634bd4c1";
            };
	    adxl345 = {
              cs_pin = "EBBCan: PB12";
              spi_software_sclk_pin = "EBBCan: PB10";
              spi_software_mosi_pin = "EBBCan: PB11";
              spi_software_miso_pin = "EBBCan: PB2";
              axes_map = "z,-y,x";
            };
            resonance_tester = {
              probe_points = "100, 100, 20";
              accel_chip = "adxl345";
            };
	    pause_resume = { };
	    display_status = { };
	    exclude_object = { };
	    virtual_sdcard.path = "/root/gcode-files";
	    display = {
	      lcd_type = "uc1701";
              cs_pin = "EXP1_3";
              a0_pin = "EXP1_4";
              rst_pin = "EXP1_5";
              encoder_pins = "^EXP2_5, ^EXP2_3";
              click_pin = "^!EXP1_2";
              contrast = 63;
              spi_software_miso_pin = "EXP2_1";
              spi_software_mosi_pin = "EXP2_6";
              spi_software_sclk_pin = "EXP2_2";
	    };
	    "neopixel btt_mini12864" = {
              pin = "EXP1_6";
              chain_count = 3;
              initial_RED = 0.1;
              initial_GREEN = 0.5;
              initial_BLUE = 0.0;
              color_order = "RGB";
            };
	    bed_mesh = {
              speed = 120;
              horizontal_move_z = 5;
              mesh_min = "35, 6";
              mesh_max = "240, 198";
              probe_count = "5, 3";
            };
            quad_gantry_level = {
              gantry_corners = "
                -60,-10
                360,370
	      ";
              points = "
                50,25
                50,225
                250,225
                250,25
	      ";
              speed = 100;
              horizontal_move_z = 10;
              retries = 5;
              retry_tolerance = 0.0075;
              max_adjust = 10;
            };
	    board_pins = {
              aliases = "
               # EXP1 header
                 EXP1_1=PE8, EXP1_2=PE7,
                 EXP1_3=PE9, EXP1_4=PE10,
                 EXP1_5=PE12, EXP1_6=PE13,    # Slot in the socket on this side
                 EXP1_7=PE14, EXP1_8=PE15,
                 EXP1_9=<GND>, EXP1_10=<5V>,

               # EXP2 header
                 EXP2_1=PA6, EXP2_2=PA5,
                 EXP2_3=PB1, EXP2_4=PA4,
                 EXP2_5=PB2, EXP2_6=PA7,      # Slot in the socket on this side
                 EXP2_7=PC15, EXP2_8=<RST>,
                 EXP2_9=<GND>, EXP2_10=<5V>
              ";
	    };
	    heater_bed = {
              heater_pin = "PA3";
              sensor_type = "Generic 3950";
              sensor_pin = "PF3";
              max_power = 0.6;
              min_temp = 0;
              max_temp = 120;
	      control = "pid";
              pid_kp = 36.899;
              pid_ki = 1.352;
              pid_kd = 251.836;
            };
	    #"temperature_sensor mcu" = {
	    #  sensor_type = "temperature_mcu";
	    #  sensor_mcu = "mcu";
	    #};
	    "temperature_sensor raspberry_pi" = {
              sensor_type = "temperature_host";
              min_temp = 10;
              max_temp = 100;
            };
            "temperature_sensor EBB_NTC" = {
              sensor_type = "Generic 3950";
              sensor_pin = "EBBCan: PA2";
            };
	    stepper_x = {
	      step_pin = "PF13";
              dir_pin = "PF12";
              enable_pin = "!PF14";
              rotation_distance = 40;
              microsteps = 32;
              full_steps_per_rotation = 200;  #set to 400 for 0.9 degree stepper
              endstop_pin = "tmc2209_stepper_x:virtual_endstop";
              position_min = 0;
              position_endstop = 300;
              position_max = 300;
              homing_speed = 25;   #Max 100
              homing_retract_dist = 0;
              homing_positive_dir = true;
	    };
            "tmc2209 stepper_x" = {
              uart_pin = "PC4";
              diag_pin = "^PG6";
              interpolate = false;
              run_current = 0.8;
              sense_resistor = 0.110;
              stealthchop_threshold = 0;
              driver_SGTHRS = 90;
	    };
            stepper_y = {
  	      step_pin = "PG0";
              dir_pin = "PG1";
              enable_pin = "!PF15";
              rotation_distance = 40;
              microsteps = 32;
              full_steps_per_rotation = 200;  #set to 400 for 0.9 degree stepper
              endstop_pin = "tmc2209_stepper_y:virtual_endstop";
              position_min = 0;
              position_endstop = 300;
              position_max = 300;
              homing_speed = 25;  #Max 100
              homing_retract_dist = 0;
              homing_positive_dir = true;
	    };
	    "tmc2209 stepper_y" = { 
	      uart_pin = "PD11";
              diag_pin = "^PG9";
              driver_SGTHRS = 90;
              interpolate = false;
              run_current = 0.8;
              sense_resistor = 0.110;
              stealthchop_threshold = 0;
	    };
	    stepper_z = {
  	      step_pin = "PF11";
              dir_pin = "PG3";
              enable_pin = "!PG5";
              rotation_distance = 40;
              gear_ratio = "80:16";
              microsteps = 32;
              endstop_pin = "probe:z_virtual_endstop";
              position_max = 260;
              position_min = -5;
              homing_speed = 8;
              second_homing_speed = 3;
              homing_retract_dist = 3;
	    };
	    "tmc2209 stepper_z" = {
	      uart_pin = "PC6";
              interpolate = false;
              run_current = 0.8;
              sense_resistor = 0.110;
              stealthchop_threshold = 0;
	    };
	    stepper_z1 = {
    	      step_pin = "PG4";
              dir_pin = "!PC1";
              enable_pin = "!PA0";
              rotation_distance = 40;
              gear_ratio = "80:16";
              microsteps = 32;
	    };
	    "tmc2209 stepper_z1" = {
	      uart_pin = "PC7";
              interpolate = false;
              run_current = 0.8;
              sense_resistor = 0.110;
              stealthchop_threshold = 0;
	    };
	    stepper_z2 = {
	      step_pin = "PF9";
              dir_pin = "PF10";
              enable_pin = "!PG2";
              rotation_distance = 40;
              gear_ratio = "80:16";
              microsteps = 32;
	    };
	    "tmc2209 stepper_z2" = {
	      uart_pin = "PF2";
              interpolate = false;
              run_current = 0.8;
              sense_resistor = 0.110;
              stealthchop_threshold = 0;
	    };
	    stepper_z3 = {
	      step_pin = "PC13";
              dir_pin = "!PF0";
              enable_pin = "!PF1";
              rotation_distance = 40;
              gear_ratio = "80:16";
              microsteps = 32;
	    };
	    "tmc2209 stepper_z3" = {
	      uart_pin = "PE4";
              interpolate = false;
              run_current = 0.8;
              sense_resistor = 0.110;
              stealthchop_threshold = 0;
	    };
	    extruder = {
              step_pin = "EBBCan: PD0";
              dir_pin = "!EBBCan: PD1";
              enable_pin = "!EBBCan: PD2";
              gear_ratio = "50:10";
              microsteps = 32;
              rotation_distance = "22.2072290";
              nozzle_diameter = "0.400";
              filament_diameter = "1.750";
              max_extrude_cross_section = 5;
              heater_pin = "EBBCan: PB13";
              sensor_type = "Generic 3950";
              sensor_pin = "EBBCan: PA3";
              control = "pid";
              min_temp = 10;
              max_temp = 270;
              max_power = 1.0;
              min_extrude_temp = 170;
              max_extrude_only_distance = 101;
              pid_Kp = 27.734;
              pid_Ki = 1.681; 
              pid_Kd = 114.406;
              pressure_advance = 0.05;
              pressure_advance_smooth_time = 0.040;
	    };
            "tmc2240 extruder" = {
              cs_pin = "EBBCan: PA15";
              spi_software_sclk_pin = "EBBCan: PB10";
              spi_software_mosi_pin = "EBBCan: PB11";
              spi_software_miso_pin = "EBBCan: PB2";
              driver_TPFD = 0;
              run_current = 0.650;
              stealthchop_threshold = 999999;
            };
            probe = {
              pin = "EBBCan: PB5";
              x_offset = 0;
              y_offset = 0;
	      z_offset = -0.360;
              speed = 10.0;
              samples = 3;
              samples_result = "median";
              sample_retract_dist = 3.0;
              samples_tolerance = 0.006;
              samples_tolerance_retries = 3;
	    };
	    fan = {
              pin = "EBBCan: PA1";
            };
            "heater_fan hotend_fan" = {
              pin = "EBBCan: PA0";
              heater = "extruder";
              heater_temp = 50.0;
            };
	    "temperature_fan controller_fan" = {
              pin = "PA8";
              kick_start_time = 0.5;
              max_power = 0.6;
              max_delta = 2;
              control = "watermark";
              shutdown_speed = 0.0;
              sensor_type = "temperature_mcu";
              min_temp = 10;
              max_temp = 80;
              target_temp = 50;
	    };
            "heater_fan exhaust_fan" = {
              pin = "PD13";
              max_power = 1.0;
              shutdown_speed = 0.0;
              kick_start_time = 5.0;
              heater = "heater_bed";
              heater_temp = 60;
              fan_speed = 1.0;
            };
	    "neopixel sb_leds" = {
              pin = "EBBCan:PD3";
              chain_count = 3;
              color_order = "GRBW";
              initial_RED = 1.0;
              initial_GREEN = 0.0;
              initial_BLUE = 1.0;
              initial_WHITE = 0.0;
	    };
            "gcode_macro CANCEL_PRINT" = {
              description = "Cancel the actual running print";
              rename_existing = "CANCEL_PRINT_BASE";
              gcode = "
              TURN_OFF_HEATERS
              CANCEL_PRINT_BASE
              ";
            };
            "gcode_macro _sb_vars".gcode = "
# User settings for the StealthBurner status leds. You can change the status colors and led
# configurations for the logo and nozzle here.
variable_colors: {
        'logo': { # Colors for logo states
            'busy': {'r': 0.4, 'g': 0.0, 'b': 0.0, 'w': 0.0},
            'cleaning': {'r': 0.0, 'g': 0.02, 'b': 0.5, 'w': 0.0},
            'calibrating_z': {'r': 0.8, 'g': 0., 'b': 0.35, 'w': 0.0},
            'heating': {'r': 0.3, 'g': 0.18, 'b': 0.0, 'w': 0.0},
            'homing': {'r': 0.0, 'g': 0.6, 'b': 0.2, 'w': 0.0},
            'leveling': {'r': 0.5, 'g': 0.1, 'b': 0.4, 'w': 0.0},
            'meshing': {'r': 0.2, 'g': 1.0, 'b': 0.0, 'w': 0.0},
            'off': {'r': 0.0, 'g': 0.0, 'b': 0.0, 'w': 0.0},
            'printing': {'r': 1.0, 'g': 0.0, 'b': 0.0, 'w': 0.0},
            'standby': {'r': 0.01, 'g': 0.01, 'b': 0.01, 'w': 0.1},
        },
        'nozzle': { # Colors for nozzle states
            'heating': {'r': 0.8, 'g': 0.35, 'b': 0.0, 'w':0.0},
            'off': {'r': 0.0, 'g': 0.0, 'b': 0.0, 'w': 0.0},
            'on': {'r': 0.8, 'g': 0.8, 'b': 0.8, 'w':1.0},
            'standby': {'r': 0.6, 'g': 0.0, 'b': 0.0, 'w':0.0},
        },
        'thermal': {
            'hot': {'r': 1.0, 'g': 0.0, 'b': 0.0, 'w': 0.0},
            'cold': {'r': 0.3, 'g': 0.0, 'b': 0.3, 'w': 0.0}
        }
    }
variable_logo_led_name:         'sb_leds' 
# The name of the addressable LED chain that contains the logo LED(s)
variable_logo_idx:              '1' 
# A comma-separated list of indexes LEDs in the logo
variable_nozzle_led_name:       'sb_leds'
# The name of the addressable LED chain that contains the nozzle LED(s). This will
# typically be the same LED chain as the logo.
variable_nozzle_idx:            '2,3'
# A comma-separated list of indexes of LEDs in the nozzle
gcode:
    # This section is required.  Do Not Delete.

            ";
            "gcode_macro _set_sb_leds".gcode = "
              {% set red = params.RED|default(0)|float %}
              {% set green = params.GREEN|default(0)|float %}
              {% set blue = params.BLUE|default(0)|float %}
              {% set white = params.WHITE|default(0)|float %}
              {% set led = params.LED|string %}
              {% set idx = (params.IDX|string).split(',') %}
              {% set transmit_last = params.TRANSMIT|default(1) %}

              {% for led_index in idx %}
                {% set transmit=transmit_last if loop.last else 0 %}
                set_led led={led} red={red} green={green} blue={blue} white={white} index={led_index} transmit={transmit}
              {% endfor %}
            ";
            "gcode_macro _set_sb_leds_by_name".gcode = "
              {% set leds_name = params.LEDS %}
              {% set color_name = params.COLOR %}
              {% set color = printer['gcode_macro _sb_vars'].colors[leds_name][color_name] %}
              {% set led = printer['gcode_macro _sb_vars'][leds_name + '_led_name'] %}
              {% set idx = printer['gcode_macro _sb_vars'][leds_name + '_idx'] %}
              {% set transmit = params.TRANSMIT|default(1) %}
              _set_sb_leds led={led} red={color.r} green={color.g} blue={color.b} white={color.w} idx={idx} transmit={transmit}
            ";
            "gcode_macro _set_logo_leds".gcode = "
              {% set red = params.RED|default(0)|float %}
              {% set green = params.GREEN|default(0)|float %}
              {% set blue = params.BLUE|default(0)|float %}
              {% set white = params.WHITE|default(0)|float %}
              {% set led = printer['gcode_macro _sb_vars'].logo_led_name %}
              {% set idx = printer['gcode_macro _sb_vars'].logo_idx %}
              {% set transmit=params.TRANSMIT|default(1) %}

              _set_sb_leds led={led} red={red} green={green} blue={blue} white={white} idx={idx} transmit={transmit}
            ";
            "gcode_macro _set_nozzle_leds".gcode = "
              {% set red = params.RED|default(0)|float %}
              {% set green = params.GREEN|default(0)|float %}
              {% set blue = params.BLUE|default(0)|float %}
              {% set white = params.WHITE|default(0)|float %}
              {% set led = printer['gcode_macro _sb_vars'].nozzle_led_name %}
              {% set idx = printer['gcode_macro _sb_vars'].nozzle_idx %}
              {% set transmit=params.TRANSMIT|default(1) %}
              _set_sb_leds led={led} red={red} green={green} blue={blue} white={white} idx={idx} transmit={transmit}
            ";
            "gcode_macro set_logo_leds_off".gcode = "
              {% set transmit=params.TRANSMIT|default(1) %}
              _set_logo_leds red=0 blue=0 green=0 white=0 transmit={transmit}
            ";
            "gcode_macro set_nozzle_leds_on".gcode = "
              {% set transmit=params.TRANSMIT|default(1) %}
              _set_sb_leds_by_name leds='nozzle' color='on' transmit={transmit}
            ";
            "gcode_macro set_nozzle_leds_off".gcode = "
              {% set transmit=params.TRANSMIT|default(1) %}
              i_set_sb_leds_by_name leds='nozzle' color='off' transmit={transmit}
            ";
            "gcode_macro status_off".gcode = "
              set_logo_leds_off transmit=0
              set_nozzle_leds_off
            ";
            "gcode_macro status_ready".gcode = "
              _set_sb_leds_by_name leds='logo' color='standby' transmit=0
              _set_sb_leds_by_name leds='nozzle' color='standby' transmit=1
            ";
            "gcode_macro status_busy".gcode = "
              _set_sb_leds_by_name leds='logo' color='busy' transmit=0
              set_nozzle_leds_on
            ";
            "gcode_macro status_heating".gcode = "
              _set_sb_leds_by_name leds='logo' color='heating' transmit=0
              _set_sb_leds_by_name leds='nozzle' color='heating' transmit=1
            ";
            "gcode_macro status_leveling".gcode = "
              _set_sb_leds_by_name leds='logo' color='leveling' transmit=0
              set_nozzle_leds_on
            ";
            "gcode_macro status_homing".gcode = "
              _set_sb_leds_by_name leds='logo' color='homing' transmit=0
              set_nozzle_leds_on
            ";
            "gcode_macro status_cleaning".gcode = "
              _set_sb_leds_by_name leds='logo' color='cleaning' transmit=0
              set_nozzle_leds_on
            ";
            "gcode_macro status_meshing".gcode = "
              _set_sb_leds_by_name leds='logo' color='meshing' transmit=0
              set_nozzle_leds_on
            ";
            "gcode_macro status_calibrating_z".gcode = "
              _set_sb_leds_by_name leds='logo' color='calibrating_z' transmit=0
              set_nozzle_leds_on
            ";
            "gcode_macro status_printing".gcode = "
              _set_sb_leds_by_name leds='logo' color='printing' transmit=0
              set_nozzle_leds_on
            ";
	    "gcode_macro PARK".gcode = "
	      {% set th = printer.toolhead %}
              G0 X{th.axis_maximum.x//2} Y{th.axis_maximum.y//2} Z30
	    ";
            "gcode_macro G32".gcode = "
              SAVE_GCODE_STATE NAME=STATE_G32
              G90
              G28
              QUAD_GANTRY_LEVEL
              G28
              G90
              PARK
              RESTORE_GCODE_STATE NAME=STATE_G32
            ";
            "gcode_macro PRINT_START".gcode = "
              {% set bedtemp = params.BED|int %}
              {% set hotendtemp = params.EXTRUDER|int %}
              {% set chambertemp = params.CHAMBER|default(0)|int %}
              G28
              QUAD_GANTRY_LEVEL
              BED_MESH_CLEAR
              BED_MESH_CALIBRATE
              G90
              G1 Z20 F3000
              M190 S{bedtemp}                                                               ; set & wait for bed temp
              #TEMPERATURE_WAIT SENSOR='temperature_sensor chamber' MINIMUM={chambertemp}   ; wait for chamber temp
              # <insert your routines here>
              M109 S{hotendtemp}                                                            ; set & wait for hotend temp
              VORON_PURGE
              # <insert your routines here>
              #G28 Z                                                                        ; final z homing
              G90                                                                           ; absolute positioning
            ";
            "gcode_macro PRINT_END".gcode = "
              #   Use PRINT_END for the slicer ending script - please customise for your slicer of choice
              # safe anti-stringing move coords
              {% set th = printer.toolhead %}
              {% set x_safe = th.position.x + 20 * (1 if th.axis_maximum.x - th.position.x > 20 else -1) %}
              {% set y_safe = th.position.y + 20 * (1 if th.axis_maximum.y - th.position.y > 20 else -1) %}
              {% set z_safe = [th.position.z + 2, th.axis_maximum.z]|min %}
    
              SAVE_GCODE_STATE NAME=STATE_PRINT_END
    
              M400                           ; wait for buffer to clear
              G92 E0                         ; zero the extruder
              G1 E-5.0 F1800                 ; retract filament
    
              TURN_OFF_HEATERS
    
              G90                                      ; absolute positioning
              G0 X{x_safe} Y{y_safe} Z{z_safe} F20000  ; move nozzle to remove stringing
              G0 X{th.axis_maximum.x//2} Y{th.axis_maximum.y - 2} F3600  ; park nozzle at rear
              M107                                     ; turn off fan
    
              BED_MESH_CLEAR
              RESTORE_GCODE_STATE NAME=STATE_PRINT_END
            ";
            "gcode_macro _HOME_X".gcode = "
              # Always use consistent run_current on A/B steppers during sensorless homing
              {% set RUN_CURRENT_X = printer.configfile.settings['tmc2209 stepper_x'].run_current|float %}
              {% set RUN_CURRENT_Y = printer.configfile.settings['tmc2209 stepper_y'].run_current|float %}
              {% set HOME_CURRENT = 0.7 %}
              SET_TMC_CURRENT STEPPER=stepper_x CURRENT={HOME_CURRENT}
              SET_TMC_CURRENT STEPPER=stepper_y CURRENT={HOME_CURRENT}

              # Home
              G28 X
              # Move away
              G91
              G1 X-10 F1200
    
              # Wait just a second… (give StallGuard registers time to clear)
              G4 P1000
              # Set current during print
              SET_TMC_CURRENT STEPPER=stepper_x CURRENT={RUN_CURRENT_X}
              SET_TMC_CURRENT STEPPER=stepper_y CURRENT={RUN_CURRENT_Y}
            ";
            "gcode_macro _HOME_Y".gcode = "
              # Set current for sensorless homing
              {% set RUN_CURRENT_X = printer.configfile.settings['tmc2209 stepper_x'].run_current|float %}
              {% set RUN_CURRENT_Y = printer.configfile.settings['tmc2209 stepper_y'].run_current|float %}
              {% set HOME_CURRENT = 0.7 %}
              SET_TMC_CURRENT STEPPER=stepper_x CURRENT={HOME_CURRENT}
              SET_TMC_CURRENT STEPPER=stepper_y CURRENT={HOME_CURRENT}

              # Home
              G28 Y
              # Move away
              G91
              G1 Y-10 F1200

              # Wait just a second… (give StallGuard registers time to clear)
              G4 P1000
              # Set current during print
              SET_TMC_CURRENT STEPPER=stepper_x CURRENT={RUN_CURRENT_X}
              SET_TMC_CURRENT STEPPER=stepper_y CURRENT={RUN_CURRENT_Y}
            ";
            "gcode_macro PAUSE" = {
              description = "Pause the actual running print";
              rename_existing = "PAUSE_BASE";
              gcode = "
                PAUSE_BASE
                _TOOLHEAD_PARK_PAUSE_CANCEL
	      ";
	    };
            "gcode_macro RESUME" = {
              description = "Resume the actual running print";
              rename_existing = "RESUME_BASE";
              gcode = "
                ##### read extrude from  _TOOLHEAD_PARK_PAUSE_CANCEL  macro #####
                {% set extrude = printer['gcode_macro _TOOLHEAD_PARK_PAUSE_CANCEL'].extrude %}
                #### get VELOCITY parameter if specified ####
                {% if 'VELOCITY' in params|upper %}
                  {% set get_params = ('VELOCITY=' + params.VELOCITY)  %}
                {%else %}
                  {% set get_params = '' %}
                {% endif %}
                ##### end of definitions #####
                {% if printer.extruder.can_extrude|lower == 'true' %}
                  M83
                  G1 E{extrude} F2100
                  {% if printer.gcode_move.absolute_extrude |lower == 'true' %} M82 {% endif %}
                {% else %}
                  {action_respond_info('Extruder not hot enough')}
                {% endif %}
                RESUME_BASE {get_params}
	      ";
	    };
	  };
	};
      };

    in {
      nixosConfigurations = {
        klopper = nixosSystem {
          system = "aarch64-linux";
          modules = [ 
	    raspberry-pi-nix.nixosModules.raspberry-pi 
	    basic-config
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
	      home-manager.users.mcgoldrickm = import ./mcgoldrickm.nix;
	    }
	  ];
        };
      };
    };
}
