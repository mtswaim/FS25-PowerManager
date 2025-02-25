# FS25 Power Manager

A Farming Simulator 25 mod that implements realistic power-based speed adjustments for implements. This mod ensures that tractors with excess horsepower can work implements faster, while preventing underpowered tractors from operating implements beyond their capabilities.

## Features

- **Dynamic Speed Adjustment**: Implements work faster when pulled by tractors with excess horsepower (up to 50% speed increase)
- **Power Requirements**: Prevents attaching implements to tractors with insufficient power
- **Multiple Implement Management**: Tracks total power requirements when multiple implements are attached
- **Safety Limits**: Implements minimum power requirements (70% of needed power) to prevent equipment damage
- **User Feedback**: Provides in-game notifications about power usage and speed adjustments

## How It Works

### Power-to-Speed Ratio
- 100% of required power = Normal operating speed
- Up to 150% of required power = Proportionally increased speed
- Below 100% but above 70% = Reduced operating speed
- Below 70% of required power = Implement cannot be attached

### Multiple Implements
- Tracks combined power requirements of all attached implements
- Prevents attaching new implements that would exceed tractor's power capacity
- Automatically detaches implements if total power requirement becomes too high

## Installation

1. Download the latest release
2. Place the zip file in your Farming Simulator 25 mods folder
3. Enable the mod in the game's mod menu

## Examples

- A 360kW tractor pulling a 360kW implement:
  - Operates at normal speed (100%)
  - Shows power usage notification
- A 500kW tractor pulling a 360kW implement:
  - Operates at increased speed (up to 139%)
  - Shows speed adjustment notification
- A 300kW tractor attempting to pull a 360kW implement:
  - Implement automatically detaches
  - Shows error message about insufficient power

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License

## Credits

Created by Matthew Swaim