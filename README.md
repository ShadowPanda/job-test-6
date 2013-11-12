# Utilizzo

Una volta fatto partire il server, collegarsi a `http://localhost:21080/`.

E' possibile specificare due parametri nell'URL (QueryString) per modificare il comportamento:

* `polling_interval`: Intervallo tra un polling e l'altro, in secondi. Il default è 5 e il minimo è 2.
* end_time`: Data e ora in cui terminare il polling. Il formato è `YYYY-MM-DD HH:MM:S` (utilizzare `` per lo spazio). Il default è 10 minuti nel futuro.

## Compatibilità

L'applicazione è compatibile con tutti i browser più recenti, sono supportate le due ultime major version di ogni browser.

Per Internet Explorer, si consiglia l'utilizzo di almeno la versione 10.

## Copyright

Copyright (C) 2013 and above Shogun (shogun@cowtech.it).

Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.