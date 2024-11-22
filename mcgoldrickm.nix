{ config, pkgs, ... }:
{
    home.packages = with pkgs; [
      zoxide
    ];

#    programs.zsh = {
#      enable = true;
#      oh-my-zsh = {
#        enable = true;
#        plugins = [ "git" "python" "ansible" "zoxide" "zsh-navigation-tools" ];
#      };
#    };
    programs.fish = {
      enable = true;
      shellAliases = {
        vi = "nvim";
	vim = "nvim";
	view = "nvim -R";
      };
      interactiveShellInit = ''
set nord0 2e3440
set nord1 3b4252
set nord2 434c5e
set nord3 4c566a
set nord4 d8dee9
set nord5 e5e9f0
set nord6 eceff4
set nord7 8fbcbb
set nord8 88c0d0
set nord9 81a1c1
set nord10 5e81ac
set nord11 bf616a
set nord12 d08770
set nord13 ebcb8b
set nord14 a3be8c
set nord15 b48ead

set fish_color_normal $nord4
set fish_color_command $nord9
set fish_color_quote $nord14
set fish_color_redirection $nord9
set fish_color_end $nord6
set fish_color_error $nord11
set fish_color_param $nord4
set fish_color_comment $nord3
set fish_color_match $nord8
set fish_color_search_match $nord8
set fish_color_operator $nord9
set fish_color_escape $nord13
set fish_color_cwd $nord8
set fish_color_autosuggestion $nord6
set fish_color_user $nord4
set fish_color_host $nord9
set fish_color_cancel $nord15
set fish_pager_color_prefix $nord13
set fish_pager_color_completion $nord6
set fish_pager_color_description $nord10
set fish_pager_color_progress $nord12
set fish_pager_color_secondary $nord1
'';
    };

    programs.starship = {
      enable = true;
      settings = {
        format = " [](#3B4252)$python$username[](bg:#434C5E fg:#3B4252)$directory[](fg:#434C5E bg:#4C566A)$git_branch$git_status[](fg:#4C566A bg:#86BBD8)$c$elixir$elm$golang$haskell$java$julia$nodejs$nim$rust[](fg:#86BBD8 bg:#06969A)$docker_context[](fg:#06969A bg:#33658A)$time[ ](fg:#33658A) ";
        command_timeout = 5000;
        add_newline = false;

        username = {
          show_always = true;
          style_user = "bg:#3B4252";
          style_root = "bg:#3B4252";
          format = "[$user ]($style)";
        };

        directory = {
          style = "bg:#434C5E";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
        };

        directory.substitutions = {
          "Documents" = "󰮜 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };

        c = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[ $symbol ($version) ]($style)";
        };

        docker_context = {
          symbol = " ";
          style = "bg:#06969A";
          format = "[ $symbol $context ]($style) $path";
        };

        elixir = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[ $symbol ($version) ]($style)";
        };

        elm = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[ $symbol ($version) ]($style)";
        };

        git_branch = {
          symbol = " ";
          style = "bg:#4C566A";
          format = "[ $symbol $branch ]($style)";
        };

        git_status = {
          style = "bg:#4C566A";
          format = "[$all_status$ahead_behind ]($style)";
        };

        golang = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[ $symbol ($version) ]($style)";
        };

        haskell = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[ $symbol ($version) ]($style)";
        };

        java = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[ $symbol ($version) ]($style)";
        };

        julia = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[ $symbol ($version) ]($style)";
        };

        nodejs = {
          symbol = "";
          style = "bg:#86BBD8";
          format = "[ $symbol ($version) ]($style)";
        };

        nim = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[ $symbol ($version) ]($style)";
        };

	nix_shell = {
          symbol = " ";
          format = "[ $symbol ($version) ]($style)";
	};

        python = {
	  symbol = " ";
          style = "bg:#3B4252";
          format = "[(\($virtualenv\) )]($style)";
        };

        rust = {
          symbol = "i ";
          style = "bg:#86BBD8";
          format = "[ $symbol ($version) ]($style)";
        };

        time = {
          disabled = false;
          time_format = "%R";
          style = "bg:#33658A";
          format = "[ $time ]($style)";
        };
       };
    };

    programs.git = {
      enable = true;
      userEmail = "michael.mcgoldrick@gmail.com";
      userName = "Michael McGoldrick";
      extraConfig = {
        core = {
          editor = "nvim";
        };
	pull = {
	  ff = "only";
	};
      };
    };
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      plugins = with pkgs.vimPlugins; [
        {
	  plugin = nord-nvim;
	  type = "lua";
	  config = ''
	    vim.cmd[[colorscheme nord]]
	  '';
	}
      ];
    };
    home.stateVersion = "24.05";
    programs.home-manager.enable = true;	

  # Make sure the nix daemon always runs
#  services.nix-daemon.enable = true;
  # Installs a version of nix, that dosen't need "experimental-features = nix-command flakes" in /etc/nix/nix.conf
 # services.nix-daemon.package = pkgs.nixFlakes;
  
  # if you use zsh (the default on new macOS installations),
  # you'll need to enable this so nix-darwin creates a zshrc sourcing needed environment changes
  # bash is enabled by default

}
