Reakce na problemy s pripravou vyvojoveho prostredi na pocitacich devcat z akce 
DjangoGirls 2016 Bratislava.

Proof of concept. Je mozne proces instalace zjednodusit? Dokaze s pomoci Dockeru
unifikovat pristup nezavisly na platforme? Je mozne zmensit porci informaci
ktere musi devcata vstrebat diky "magii" kolem vyvojoveho prostredi a deploye?

# Co resim

- jednodussi start vyvojoveho prostredi v pocitacich ucastnic akce typu DjangoGirls
- minimalizovat pocet instalaci noveho SW do jejich systemu
- minimalizovat pocet registraci do sluzeb tretich stran
- unifikaci prostredi napric systemy (Linux, Windows, OSX)

# Proc to resim

- vychazim z vlastni zkusenosti ziskane z postu mentora na DjangoGirls
  Bratislava (2016-03-13)
- priprava a konfigurace systemu v me skupine zabrala minimalne 1/4 z celkoveho
  casu; strasne me mrzelo, ze se do ni muselo nalit tolik energie, ktera nam
  pak v zaveru akce chybela
- podle reakci organizatoru a lidi zapojenych do akce soudim, ze hlavnim
  smyslem akce je prezentovat devcatum programovani jako zabavnou praci, se
  kterou se da slusne zivit; z teto pozice mi pripada zbytecne vysvetlovat
  nastroje a postupy bezne pro webovou praxi (byt jsou `git` i `virtualenv`
  duleziti, zabavni nejsou ani trochu!), a namisto toho se soustredit na
  peknejsi cast cele akce (tedy programovani v Pythonu a Djangu)
- behem workshopu musi devcata vstrebat **kvanta** informaci, hodne z nich 
  ale jen hlavou protecou; hlasky typu "je to jen samy copy/paste" jsem slysel
  nejednou; verim, ze zjednoduseni tutorialu, nebo alespon rutinnich veci okolo 
  nej (deployment), uvolni holkam mozkovou kapacitu pro dulezitejsi veci

# Jak to resim

- namisto instalace Pythonu a virtualenvu pouzivam Docker Toolbox
- namisto Pythonu nainstalovaneho v systemu pouzivam kontejner s Pythonem
- dovnitr kontejneru (s binarnim Python prostredim, tj. patricnou verzi
  Pythonu a balicky pro nej) je nasdilen adresar `src/`, ve kterem jsou 
  zdrojove kody jejich aplikace; jinymi slovy, zdrojaky maji devcata na svych 
  pocitacich a edituji je v programu na ktery jsou zvykle
- na ovladani prostredi pouzivam wrapper skript, ktery ma naimplementovan 
  jednotky subcommandu pro rutinni operace (viz nize)


# Ovladani `djg.sh`

Behem celeho workshopu devcata komunikuji s Pythonem a Djangem prostrednictvim
wrapper skriptu `djg.sh`, resp. pres nektery z jeho subcommandu:

## Predpoklady

* nainstalovany [Docker toolbox](https://www.docker.com/products/docker-toolbox)
* v adresari mam 3 klicove soubory: [`config`](config), [`djg.sh`](djg.sh) a 
  [`Dockerfile`](Dockerfile)
* obsah souboru [`config`](config) je prizpusoben lokalnimu prostredi (typicky 
  staci zmenit obsah promennych `USERNAME` a `DOCKER_REPOSITORY`)
* v adresari mam vytvoren prazdny podadresar `src/`

## Subcommandy

### `build`

Namisto Pythonu a virtualenvu pouzivame Docker kontejner, ktery ma oboji vevnitr.
Vyhodou je, ze pokud by nejaky konkretni balicek potreboval doinstalovat do 
systemu novou knihovnu, da se instalace pridat do `Dockerfile` souboru.

Pro vytvoreni kontejneru je treba zavolat:

    $ ./djg.sh build

Vznikne novy kontejner pojmenovovany podle promennych $DOCKER_REPOSITORY a $USERNAME
ze souboru `config` (napr. `djangogirls/bratislava-2016-03-13:slavka`).

Pokud existuje soubor `src/requirements.txt`, bude behem buildu nacten a seznam
balicku bude dovnitr kontejneru nainstalovan. Pokud neexistuje, nainstaluje se
pouze Django verze 1.9.

### `init <PROJEKT>`

Subcommand `init` je jednoduchy wrapper kolem `django-admin.py startproject <PROJEKT> .`.
Vola se pouze 1x na pocatku kurzu, idealne hned po prvnim `buildu`. Po jeho
dokonceni bude v adresari `src/` zakladni kostra nove Django aplikace.

Priklad pouziti:

    $ ./djg.sh build mysite

### `shell`

Alias pro `./manage.py shell`. Po jeho spusteni se objevi interaktivni Python
konzole.

Priklad pouziti:

    $ ./djg.sh shell

### `local`

Alias pro prikazy `./manage.py migrate` a `./manage.py runserver`. Pokazde kdyz
bude tento prikaz spusten, budou aplikovany migrace a nahozen vyvojovy server.
Na stdout bude vypsana IP adresa a port, na kterou se runserver zavesil.

Oba kroky je mozne vyvolat i manualne s pomoci subcommandu `manage`, ale prislo
mi lepsi je sloucit do jedineho kroku, a ten jednoznacne pojmenovat tak, aby
holky chapaly ze pousti neco u sebe, na vlastnim pocitaci.

Priklad:

    $ ./djg.sh local

### `manage`

Alias pro `./manage.py`. Obecny nastroj, pres ktery je mozne poustet dalsi 
subcommandy Djanga (napr. `makemigrations`, `collectstatic`, apod.)

Priklad pouziti:

    $ ./djg.sh manage
    
## Konfiguracni soubor [`config`](config)

Zedituj soubor `config` podle vlastnich potreb. Prinejmensim by si mel nastavit
hodnoty pro `USERNAME` a `DOCKER_REPOSITORY`, napr.:

    USERNAME=slavka
    DOCKER_REPOSITORY=djangogirls/bratislava-2016-03-13

Na zbytek hodnot neni treba sahat.

Tento soubor by mel idealne generovat system. Napr. po registraci devcat na
djangogirls.com by mohly mit svou sekci za prihlasenim, kde by byly uvedeny
zakladni informace a odkazy na klicove soubory. Konfigurak by mohl byt jeden 
z nich.
    
# Ukazka pouziti

![Demonstrace wrapper skriptu](assets/demo.gif)

# Nevyhody

- jedna velka magie
- netypicky pristup, v komunite je obvykle Python primo v systemu a spolu s virtualenv
- dalsi vrstva pro pochopeni (Docker); v prubehu skoleni by ale k nemu devcata
  vubec nemusela pricichnout, vse je odstineno wrapper skriptem
- vetsi narocnost na system (volne misto na disku)
- nutnost custom konfigurace uvnitr [`config`](config)

# TODO

- implementovat prikaz `deploy` 
- vyzkouset postup na Windowsech
