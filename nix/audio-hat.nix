# audio-hat.nix
{ config, lib, pkgs, ... }:
{
  hardware.deviceTree.enable = true;

  hardware.deviceTree.overlays = [{
    name = "tas5756m-i2s3";
    dtsText = ''
      /dts-v1/;
      /plugin/;
      / {
        compatible = "radxa,zero3", "rockchip,rk3566";

        /* I2S3 controller on the M0 header pins (12/35/38/40) */
        fragment@0 {
          target = <&i2s3_2ch>;
          __overlay__ {
            #sound-dai-cells = <0>;
            rockchip,trcm-sync-tx-only;
            pinctrl-names = "default";
            pinctrl-0 = <&i2s3m0_sclk &i2s3m0_lrck &i2s3m0_sdi &i2s3m0_sdo>;
            status = "okay";
          };
        };

        /* Declare the codec at BOTH straps; only the present one binds */
        fragment@1 {
          target = <&i2c3>;
          __overlay__ {
            #address-cells = <1>;
            #size-cells = <0>;
            pinctrl-names = "default";
            pinctrl-0 = <&i2c3m0_xfer>;
            status = "okay";
            tas5756_4d: tas5756@4d {
              compatible = "ti,tas5756";
              reg = <0x4d>;
              #sound-dai-cells = <0>;
              status = "okay";
            };
            tas5756_4c: tas5756@4c {
              compatible = "ti,tas5756";
              reg = <0x4c>;
              #sound-dai-cells = <0>;
              status = "okay";
            };
          };
        };

        /* One card per address, same name so hw:TAS5756M always resolves */
        fragment@2 {
          target-path = "/";
          __overlay__ {
            sound_4d: tas5756-sound-4d {
              compatible = "simple-audio-card";
              simple-audio-card,name = "TAS5756M";
              simple-audio-card,format = "i2s";
              simple-audio-card,mclk-fs = <256>;
              simple-audio-card,bitclock-master = <&cpu_4d>;
              simple-audio-card,frame-master = <&cpu_4d>;
              status = "okay";
              cpu_4d:   simple-audio-card,cpu   { sound-dai = <&i2s3_2ch>; };
              codec_4d: simple-audio-card,codec { sound-dai = <&tas5756_4d>; };
            };
            sound_4c: tas5756-sound-4c {
              compatible = "simple-audio-card";
              simple-audio-card,name = "TAS5756M";
              simple-audio-card,format = "i2s";
              simple-audio-card,mclk-fs = <256>;
              simple-audio-card,bitclock-master = <&cpu_4c>;
              simple-audio-card,frame-master = <&cpu_4c>;
              status = "okay";
              cpu_4c:   simple-audio-card,cpu   { sound-dai = <&i2s3_2ch>; };
              codec_4c: simple-audio-card,codec { sound-dai = <&tas5756_4c>; };
            };
          };
        };

        /* Optional: mute HDMI audio so this becomes card 0 */
        fragment@3 {
          target = <&hdmi_sound>;
          __overlay__ { status = "disabled"; };
        };

        fragment@4 {
          target = <&gpio3>;
          __overlay__ {
            amp_unmute_hog {
              gpio-hog;
              gpios = <20 0>;
              output-high;
              line-name = "tas5756-unmute";
            };
          };
        };
      };
    '';
  }];

  boot.kernelModules = [ "snd_soc_pcm512x" "snd_soc_pcm512x_i2c" "snd_soc_simple_card" ];
  environment.systemPackages = with pkgs; [ i2c-tools alsa-utils libgpiod ];
}

