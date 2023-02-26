<div align ="center">
<h3>GSI Tool Bebonia </h3>
<b>A script to automate somethings related to gsis for redmi note 8 pro. Currently only aosp roms are supported.
</div><br>
<h2>Features:</h2>

- Debloat useless treble overlays
- Debloat google bloat
- Add bluetooth fix props
- ~~Add Aperture Camera~~ (Not added yet)
- Add extra overlays for wifi and signal icons, will only work the roms which has "Themes" section that lets you to change wifi, signal icons etc
- Convert .img to .new.dat.br to use in flashable zips
- Umount image after finishing jobs
- Shrink image to reduce image size<br>
<h2>Usage:</h2>

- Create an empty dir
```
mkdir gsi && cd gsi
```
- Clone gsi tool
```
git clone https://github.com/MrErenK/gsi-tool-bebonia.git
```
- Give required permissions to script path
```
chmod -R +x gsi-tool-bebonia && cd gsi-tool-bebonia
```
- Run script
```
./script.sh -path "/path/to/gsi/image" <flags>
```
- Example
```
./script.sh -path ~/Downloads/system.img -debloat -add_extra_overlays -fix_bt
```
- Supported flags:
```
[-help]: To view help page

You should use atleast two flag below.

[-path]: Path to the gsi image (The script will automatically mount the image)
[-make_datbr]: Convert img to new.dat.br
[-debloat]: Debloat gsi
[-add_extra_overlays]: Add more wifi and signal icons
[-bt_fix]: Add bluetooth fix props
[-umount]: Umount the image after finishing jobs (by default it will not umount for future changes etc)
[-resize]: Shrink the image file
[-add_aperturecam]: Add Aperture Camera as a system app [Currently not available]
```
</b>
<br>
<h2>Credits:</h2>

- [Converting to .new.dat.br](https://github.com/xiaoxindada/SGSI-build-tool)
- [Extra Overlays](https://github.com/MrErenK/Extra-Overlays/#credits)<br>
