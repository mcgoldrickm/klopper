{
  description = "raspberry-pi-nix example";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
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
        ];

        programs.fish.enable = true;
	services.sshd.enable = true;

	services.klipper = {
	  enable = true;
	  firmwares = {
	    mcu = {
	      enable = true;
              configFile = btt-octopus.config;
	      serial = "/dev/serial/by-id/usb-Klipper_stm32f446xx_180018000550335331383820-if00";
            };
	    mcu = {
	      enable = true;
	      configFile = ebb-can.config;
	      canbus_uuid = "8ca6634bd4c1";
	    };
	  };
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
              mesh_min = 35, 6;
              mesh_max = 240, 198;
              probe_count = 5, 3;
            };
            quad_gantry_level = {
              gantry_corners = {
                -60,-10;
                360,370;
	      };
              points = {
                50,25;
                50,225;
                250,225;
                250,25;
	      };
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
            };
	    "temperature_sensor mcu" = {
	      sensor_type = "mcu";
	    };
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
              homing_positive_dir = true
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
              endstop_pin: "tmc2209_stepper_y:virtual_endstop";
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
	  };
	};


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
          interfaces = {
            wlan0.useDHCP = true;
            eth0.useDHCP = true;
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
