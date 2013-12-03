BTC-E BOT (version 1.x)
============
Author: explode48 (explode48@gmail.com)  
ULR: http://proapi.ru/btce_bot/  
License: GNU General Public License v2

###DESCRIPTION:
Trade bot for BTC-E.COM exchange, uses the simplest strategy - buy cheap, sell expensive. Any statistical analysis of the exchange before the creation of orders given. However, the bot performs well on the game at small rate fluctuations.

###INSTALLATION INSTRUCTIONS:
1) Download the archive with the latest version of the program and unzip it into any directory.  
2) Run the file btce_bot.exe. After the appearance of the console window, close it (you should see the configuration file config.ini).  
3) Open with any text editor config.ini file and, if necessary, change the following settings:  
`[api]`  
`akey = XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX # API key`  
`asec = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx # Secret string`  
`[bot]`  
`curpair = btc_usd # Currency pair`  
`mins = 0.010000 # Minimum number of currencies for sell`  
`minb = 0.010000 # Minimum number of currencies for buy`  
`maxs = 0.010000 # Maximum number of currencies for sell`  
`maxb = 0.010000 # Maximum number of currencies for sale`  
`diff = 0.500000 # The difference between the current rate and created orders`  
`bttl = 360 # Lifetime buy orders (in minutes, 0 - off)`  
`delay = 60 # The delay (in seconds) between the actions`  
`verb = 0 # Extended mode information output (0 - off, 1 - on)`  
`logf = log.txt # Name of the file that will be duplicated output information (if necessary)`  
`update = 1 # Automatic check for updates (0 - off, 1 - on)`  
4) Run the file btce_bot.exe to start trading.

###ADDITIONAL INFORMATION:
During the bot is undesirable to manually any actions currency used in the chosen currency pair (may cause unpredictable errors).  
To run multiple copies of the bot should use different API keys.  
Application supports several startup options. For more information, start with the key -h (or --help).

###CHANGELOG:
Version 1.2.7.12:  
    * Fixed incorrect handling of the parameter "diff" on some currency pairs.  
Version 1.2.4.8:  
    * Added option to specify the lifetime of buy orders (bttl);  
    * Changes in the auto-update system;  
    * Removed utility get_info.exe, included with the program.  
Version 1.0.0.0:  
    * First public release.

###DONATIONS:
I would be grateful for any financial help!  
Your donations provide the motivation to work on new versions of the software.  
http://proapi.ru/contacts/#donate

© PRO API, 2013
