<div class="interkasssa" style="text-align: center;">
    <p>
        <img class='img-responsive center-block' src='/styles/default_adm/img/paysys_logo/interkassa-logo.png'>
    </p>

    <form name='payment_interkassa' method='POST' action='javascript:selpayIK.selPaysys()'>

        %HIDDEN_FIELDS%

        <button class="btn btn-primary">_{PAY}_</button>
    </form>

        %PS_HTML%

    <!--<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>-->

    <script>
        var interkassa_lang = [];
        var interkassa_conf = [];
        interkassa_lang.error_selected_currency  = '%text_interkassa_not_selected_currency%';
        interkassa_lang.something_wrong  = '%text_interkassa_something_wrong%';
        interkassa_conf.PAYMENT_SYSTEM = '%PAYMENT_SYSTEM%';
    </script>
    <script src="/styles/default_adm/js/interkassa.js"></script>
</div>