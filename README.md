BTC-E BOT (version 1.x)
============
Author: explode48 (explode48@gmail.com)  
ULR: http://proapi.ru/btce_bot/  
License: GNU General Public License v2

###DESCRIPTION:
Trade bot for BTC-E.COM exchange, uses the simplest strategy - buy cheap, sell expensive. Any statistical analysis of the exchange before the creation of orders given. However, the bot performs well on the game at small rate fluctuations.

###INSTALLATION INSTRUCTIONS:
1) Download the archive with the latest version of the program and unzip it into any directory.  
2) Run the file btce_bot.exe. After the appearance of the program window, close it (you should see the configuration file config.ini).  
3) Open with any text editor config.ini file and, if necessary, change the following settings:  
`[api]`  
`key = XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX # API key`  
`secret = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx # Secret string`  
`[proxy]`  
`host = 123.123.123.123:8080 # Address of the proxy server (if necessary)`  
`login = user # Username to access the proxy server (if necessary)`  
`pass = 12345 # Password to access the proxy server (if necessary)`  
`[log]`  
`file = log.txt # Name of the file that will be duplicated output information (if necessary)`  
`scroll = 1 # Automatic scrolling for message windows (0 - off, 1 - on)`  
`verbose = 0 # Extended mode information output (0 - off, 1 - on)`  
`[bot]`  
`curpair = btc_usd # Currency pair`  
`min_sell = 0.010000 # Minimum number of currencies for sell`  
`min_buy = 0.010000 # Minimum number of currencies for buy`  
`max_sell = 0.010000 # Maximum number of currencies for sell`  
`max_buy = 0.010000 # Maximum number of currencies for sale`  
`difference = 0.500000 # The difference between the current rate and created orders`  
`buy_ttl = 360 # Lifetime buy orders (in minutes, 0 - off)`  
`delay = 60 # The delay (in seconds) between the actions`  
`fall_def = 1 # Protection from purchases on dips (0 - off, 1 - on)`  
`[application]`  
`autorun = 0 # Automatic start trading at bot startup`  
4) Run the file btce_bot.exe and click "Run BOT" to start trading.

###ADDITIONAL INFORMATION:
During the bot is undesirable to manually any actions currency used in the chosen currency pair (may cause unpredictable errors).  
To run multiple copies of the bot should use different API keys.  
Application supports several startup options. For more information, start with the key -h (or --help).

###CHANGELOG:
Version 1.4.0.0:  
    * Added information banner;  
    * Now you can activate autoscroll for message window;  
    * Supports proxy;  
    * Little changed file format of settings;  
    * Fixed the following currency pairs: LTC/EUR, NMC/USD and NVC/USD;  
    * Other minor changes.  
Version 1.3.9.169:  
    * Optimized source code of header files;  
    * Added an option to automatically run the bot at startup (autorun);  
    * Added option to protect against purchases on dips (falldef);  
    * Restart bot using buttons Run BOT/Stop BOT now works correctly;  
    * Added the ability to close the program while trading;  
    * Other minor changes.  
Version 1.3.4.142:  
    * Outdated method OrderList replaced by a new ActiveOrders;  
    * Removed system automatically check and download updates;  
    * Added a graphical interface.  
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
