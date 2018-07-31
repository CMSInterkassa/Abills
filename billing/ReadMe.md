## Инструкция по установке и настройке

 тестировался модуль на ABillS 0.77.77
 
### Скопировать файлы в требуемые директории:

Основной файл модуля **Interkassa.pm**
 /usr/abills/Abills/modules/Paysys/systems/

шаблоны модуля **paysys_interkassa.tpl** и **paysys_interkassa_ps.tpl**
 /usr/abills/Abills/modules/Paysys/templates

Папку **paysys_interkassa**
 /usr/abills/cgi-bin/img/

**interkassa.css**
 /usr/abills/cgi-bin/styles/default_adm/css/

**interkassa.js**
 /usr/abills/cgi-bin/styles/default_adm/js/

логотип модуля **interkassa-logo.png**
 /usr/abills/cgi-bin/styles/default_adm/img/paysys_logo


### Перейти в папку /usr/abills/Abills/modules/Paysys

#### Добавить языковые переменные в файл **lng_russian.pl**
```
$lang{text_interkassa_select_payment_method} = 'Выберите удобный способ оплаты';
$lang{text_interkassa_select_currency} = 'Укажите валюту';
$lang{text_interkassa_press_pay} = 'Нажмите &laquo;Оплатить&raquo;';
$lang{text_interkassa_pay_through} = 'Оплатить через';
$lang{text_interkassa_not_selected_currency} = 'Вы не выбрали валюту';
$lang{text_interkassa_something_wrong} = 'Что то пошло не так';
```

#### Добавить языковые переменные в файл **lng_english.pl**
```
$lang{text_interkassa_select_payment_method} = 'Select a convenient payment method';
$lang{text_interkassa_select_currency} = 'Specify currency';
$lang{text_interkassa_press_pay} = 'Click &laquo;Pay&raquo;';
$lang{text_interkassa_pay_through} = 'Pay by';
$lang{text_interkassa_not_selected_currency} = 'You have not selected a currency';
$lang{text_interkassa_something_wrong} = 'Something wrong';
```

#### Открыть файл **webinterface**
в начале файла найти hash переменную
```
my %PAY_SYSTEMS = ( ... )
```

добавить в список масива код
```
  200=> 'Interkassa',
```

Найти в файле описание метода paysys_payment
```
sub paysys_payment {...}
```

внутри метода будет на 1100+ строке примерно такой код
```
  elsif($FORM{PAYMENT_SYSTEM} == 125) {
    paysys_electrum();
  }
  elsif($FORM{PAYMENT_SYSTEM} == 126) {
    paysys_plategka();
  }
```

после него добавить следующий:
```
  elsif($FORM{PAYMENT_SYSTEM} == 200) {

    require Paysys::systems::Interkassa;

    Paysys::systems::Interkassa->import();
    my $Interkassa = Paysys::systems::Interkassa->new(\%conf, \%FORM, \%lang, \%ENV, $user, {HTML => $html, SELF_URL => $SELF_URL, DATETIME => "$DATE $TIME"});

    my %outputIk = $Interkassa->paysys_interkassa();

    return $html->tpl_show(_include('paysys_interkassa', 'Paysys'),
        {
            HIDDEN_FIELDS => $outputIk{HIDDEN_FIELDS},
            PS_HTML => $outputIk{PS_HTML},
            PAYMENT_SYSTEM => $FORM{PAYMENT_SYSTEM},
            text_interkassa_not_selected_currency => $lang{text_interkassa_not_selected_currency},
            text_interkassa_something_wrong => $lang{text_interkassa_something_wrong},
        },
        $attr->{OUTPUT2RETURN}
    );
  }
```


#### Отрыть файл **paysys_check.cgi** и найти описание метода paysys_payments
```
sub paysys_payments { ... }
```
Добавить внутри метода следующий код:
```
  if ($ENV{QUERY_STRING} eq 'interkassa_api') {

    require Paysys::systems::Interkassa;

    Paysys::systems::Interkassa->import();
    my $Interkassa = Paysys::systems::Interkassa->new(\%conf, \%FORM, undef, undef, $users,
    { HTML => $html, SELF_URL => $SELF_URL, DATETIME => "$DATE $TIME" });

    print "Content-Type: text/html\n\n";
    print $Interkassa->apiAnswer();
    return 1;
  }

  if ($ENV{QUERY_STRING} eq 'interkassa') {

    require Paysys::systems::Interkassa;

    Paysys::systems::Interkassa->import();
    my $Interkassa = Paysys::systems::Interkassa->new(\%conf, \%FORM, undef, undef, undef,
    { HTML => $html, SELF_URL => $SELF_URL, DATETIME => "$DATE $TIME" });

    print "Content-Type: text/html\n\n";
    print $Interkassa->check_payment();
    return 1;
  }
```

### Заходим в админку по пути _**Настройка→Paysys→Настройки**_
в списке платежных модулей должен появится **Interkassa**, открываем редактирование настроек и заполняем поля:

- PAYSYS_INTERKASSA_TEST_MODE   - тестовый режим, возможные значения 1 или 0.
- PAYSYS_INTERKASSA_CURRENCY    - в какой валюте будут проводится платежи, возможные значения UAH, USD, EUR, RUB.
- PAYSYS_INTERKASSA_CASHBOX_ID  - идентификатор касы в Interkassa.
- PAYSYS_INTERKASSA_SECRET_KEY  - секретный ключ в Interkassa.
- PAYSYS_INTERKASSA_TEST_KEY    - тестовый ключ в Interkassa.
- PAYSYS_INTERKASSA_API_ENABLE  - вкл. режим API, возможные значения 1 или 0.
- PAYSYS_INTERKASSA_API_ID      - идентификатор API в Interkassa.
- PAYSYS_INTERKASSA_API_KEY     - API ключ в Interkassa.