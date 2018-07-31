package Paysys::systems::Interkassa;

=head1 Interkassa
  module for Interkassa payment system

  Date: 31.07.2018
=cut

use strict;
use warnings FATAL => 'all';

use parent 'main';

use Abills::Base qw(load_pmodule _bp);
use Abills::Fetcher;
require Abills::Templates;
require Paysys::Paysys_Base;
our $PAYSYSTEM_VERSION = '1.00';

my $CONF;

my $PAYSYSTEM_NAME       = 'Interkassa';
my $PAYSYSTEM_SHORT_NAME = 'Interkassa';

my $PAYSYSTEM_ID         = 200;

my $PAYSYSTEM_IP         = '151.80.190.97,151.80.190.98,151.80.190.99,151.80.190.100,151.80.190.101,151.80.190.102,151.80.190.103,151.80.190.104';
my $PAYSYSTEM_IP_begin   = '151.80.190.97';
my $PAYSYSTEM_IP_end     = '151.80.190.104';

my $PAYSYSTEM_EXT_PARAMS = '';

my $PAYSYSTEM_CLIENT_SHOW = 1;
my $DEBUG = 1;

my $TEST_MODE = 1;

my %PAYSYSTEM_CONF = (
  PAYSYS_INTERKASSA_TEST_MODE => 0,
  PAYSYS_INTERKASSA_CURRENCY => 'UAH',
  PAYSYS_INTERKASSA_CASHBOX_ID => '',
  PAYSYS_INTERKASSA_SECRET_KEY => '',
  PAYSYS_INTERKASSA_TEST_KEY => '',
  PAYSYS_INTERKASSA_API_ENABLE => '',
  PAYSYS_INTERKASSA_API_ID => '',
  PAYSYS_INTERKASSA_API_KEY => '',
);

my ($json, $html, $user, $SELF_URL, $DATETIME, $OUTPUT2RETURN);
our $users;

sub new {
  my $class = shift;

  my $CONF = shift;
  my $FORM = shift;
  my $lang = shift;
  my $ENV = shift;
  my $user = shift;
  $user->pi({UID => $user->{UID}});
  my $attr = shift;
  $DEBUG = $CONF->{PAYSYS_DEBUG} || 1;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{SELF_URL}) {
    $SELF_URL = $attr->{SELF_URL};
  }

  if ($attr->{DATETIME}) {
    $DATETIME = $attr->{DATETIME};
  }

  my $self = {
    conf  => $CONF,
    lang  => $lang,
    FORM  => $FORM,
    ENV => $ENV,
    user => $user,
    DATETIME => $DATETIME,
  };

  bless($self, $class);

  return $self;
}

sub paysys_interkassa {
    use MIME::Base64;
    use Digest::MD5 qw(md5 md5_hex md5_base64);
    use JSON;
    my $self = shift;

    my $index = $self->{FORM}->{index};
    my $url_callback = "https://$self->{ENV}{SERVER_NAME}:$self->{ENV}{SERVER_PORT}/paysys_check.cgi?interkassa";
    my $url_succ = "https://$self->{ENV}{SERVER_NAME}:$self->{ENV}{SERVER_PORT}$self->{ENV}{REQUEST_URI}?index=44";
    my $url_fail = "https://$self->{ENV}{SERVER_NAME}:$self->{ENV}{SERVER_PORT}$self->{ENV}{REQUEST_URI}?index=44";
#    my $url_succ = "https://$self->{ENV}{SERVER_NAME}:$self->{ENV}{SERVER_PORT}$self->{ENV}{REQUEST_URI}?index=$index&PAYMENT_SYSTEM=$self->{FORM}{PAYMENT_SYSTEM}&interkassa_transaction=$self->{FORM}->{OPERATION_ID}";
#    my $url_fail = "https://$self->{ENV}{SERVER_NAME}:$self->{ENV}{SERVER_PORT}$self->{ENV}{REQUEST_URI}?index=$index&PAYMENT_SYSTEM=$self->{FORM}{PAYMENT_SYSTEM}&interkassa_transaction=FALSE&trans_num=$self->{FORM}->{OPERATION_ID}";

    my %formData = (
        'ik_am'     => $self->{FORM}->{SUM},
        'ik_cur'    => ($self->{conf}->{PAYSYS_INTERKASSA_CURRENCY})? $self->{conf}->{PAYSYS_INTERKASSA_CURRENCY} : 'UAH',
        'ik_co_id'  => $self->{conf}->{PAYSYS_INTERKASSA_CASHBOX_ID},
        'ik_pm_no'  => $self->{FORM}->{OPERATION_ID},
        'ik_desc'   => "#$self->{FORM}->{OPERATION_ID}",
        'ik_ia_u'   => $url_callback,
        'ik_suc_u'  => $url_succ,
        'ik_pnd_u'  => $url_succ,
        'ik_fal_u'  => $url_fail,
        'ik_x_user' => $self->{user}->{UID},
    );

    if($self->{conf}->{PAYSYS_INTERKASSA_TEST_MODE}){
        $formData{ik_pw_via} = "test_interkassa_test_xts";
    }

    my $str = '';
    foreach my $key (sort keys %formData) {
       if ($key =~ m/ik_/){ $str.= $formData{$key} . ':'; }
    }
    $str .= $self->{conf}->{PAYSYS_INTERKASSA_SECRET_KEY};

    my $md5_sign = md5($str);
    my $sign = encode_base64($md5_sign, '');

    $formData{ik_sign} = $sign;

#    my $str_args = $self->ikStringForSign(\%formData);
#    $formData{ik_sign} = $self->ikSignFormation($str_args, $self->{conf}->{PAYSYS_INTERKASSA_SECRET_KEY});

    my $hidden_fields = "";

    foreach my $key (keys %formData) {
        $hidden_fields.= '<input type="hidden" name="' . $key . '" value="' . $formData{$key} . '" />';
    }

    my $ps_html = "";
    if($self->{conf}->{PAYSYS_INTERKASSA_API_ENABLE}){
        my %payment_systems = $self->getIkPaymentSystems(
            $self->{conf}->{PAYSYS_INTERKASSA_API_ID},
            $self->{conf}->{PAYSYS_INTERKASSA_API_KEY},
            $self->{conf}->{PAYSYS_INTERKASSA_CASHBOX_ID}
        );

        if(!$payment_systems{error}){
            my $image_path = "/img/paysys_interkassa/";
            foreach my $ps (keys %payment_systems) {
                my $title = $payment_systems{$ps}{title};
                my $image_path_ps = $image_path.$ps;
                $ps_html.= qq {
                    <div class='col-sm-3 text-center payment_system'>
                        <div class='panel panel-warning panel-pricing'>
                            <div class='panel-heading'>
                                <div class='panel-image'>
                                    <img src='$image_path_ps.png' alt='$title'>
                                </div>
                            </div>
                            <div class='form-group'>
                                <div class='input-group'>
                                    <div class='radioBtn btn-group'>
                };

                foreach my $currency (keys %{$payment_systems{$ps}{currency}}) {
                    my $currencyAlias = $payment_systems{$ps}{currency}{$currency};
                    $ps_html.= qq{
                    <a class='btn btn-primary btn-sm notActive' data-toggle='fun' data-title='$currencyAlias'>
                            $currency
                    </a>
                    };
                }

                $ps_html.= qq{
                                    </div>
                                </div>
                            </div>
                            <div class='panel-footer'>
                                <a class='btn btn-lg btn-block btn-success ik-payment-confirmation'
                                   data-title='$ps' href='#'>
                                   $self->{lang}->{text_interkassa_pay_through}<br><strong>$title</strong>
                                </a>
                            </div>
                        </div>
                    </div>
                };
            }

            $ps_html = $html->tpl_show( main::_include('paysys_interkassa_ps', 'Paysys'),
                    {
                        PS_LIST => $ps_html,
                        text_interkassa_select_payment_method => $self->{lang}->{text_interkassa_select_payment_method},
                        text_interkassa_select_currency => $self->{lang}->{text_interkassa_select_currency},
                        text_interkassa_press_pay => $self->{lang}->{text_interkassa_press_pay},

                    }, { OUTPUT2RETURN => 1 }
                );
        } else {
            $ps_html = $payment_systems{error};
        }
    }

    my %output = (
        HIDDEN_FIELDS => $hidden_fields,
        PS_HTML => $ps_html,
    );

    return %output;
}

sub apiAnswer {
    use MIME::Base64;
    use Digest::MD5 qw(md5 md5_hex md5_base64);

    my $self = shift;

    my %form = ();
    my $data;
    foreach my $key(keys %{$self->{FORM}}){
        if ($key =~ m/ik_/){
            my $value = $self->{FORM}->{$key};
            $form{$key} = $value;
        }
    }

    if ($form{ik_sign}){ delete $form{ik_sign}; }
    my $str = '';
    foreach my $key (sort keys %form) {
        if ($key =~ m/ik_/){ $str.= $form{$key} . ':'; }
    }
    $str .= $self->{conf}->{PAYSYS_INTERKASSA_SECRET_KEY};

    my $md5_sign = md5($str);
    my $sign = encode_base64($md5_sign, '');

    if (exists $form{ik_act} && $form{ik_act} eq 'process'){
        $form{ik_sign} = $sign;

#        my $str_args = $self->ikStringForSign(\%form);
#        $form{ik_sign} = $self->ikSignFormation($str_args, $self->{conf}->{PAYSYS_INTERKASSA_SECRET_KEY});

        $data = $self->getAnswerFromAPI(\%form);
    } else {
        $data = $sign;
#        my $str_args = $self->ikStringForSign(\%form);
#        $data = $self->ikSignFormation($str_args, $self->{conf}->{PAYSYS_INTERKASSA_SECRET_KEY});
    }

    return $data;
}

sub getAnswerFromAPI {
    use LWP::UserAgent;
    use JSON;

    my $self = shift;

    my $data2 = '';
    my %form = ();
    foreach my $key(keys %{$self->{FORM}}){
        if ($key =~ m/ik_/){
            my $value = $self->{FORM}->{$key};
            $form{$key} = $value;
        }
    }

    my $url = 'https://sci.interkassa.com/';
    my $req = HTTP::Request->new(POST => $url);

    use URI qw( );
    my $uri = URI->new('', 'http');
    $uri->query_form(\%form);
    my $query = $uri->query;

    $req->content($query);
    my $browser = LWP::UserAgent->new;
    my $result = $browser->post( $url, \%form );

    if ($result->is_success) {
        return $result->decoded_content;
    }
    else {
        return "HTTP POST error code: " . $result->code . "\nHTTP POST error message: " . $result->message . "\n";
    }
}

sub ikStringForSign {
     my %data = @_;
     my $str_args = '';

     if ($data{ik_sign}){ delete $data{ik_sign}; }

     foreach my $key (sort keys %data) {
         if ($key =~ m/ik_/){
             $str_args.= $data{$key} . ':';
         }
     }

     return $str_args;
}

sub ikSignFormation {
    use MIME::Base64;
    use Digest::MD5 qw(md5 md5_hex md5_base64);

    my $self = shift;

    my ($str_args, $secret_key) = @_;

    $str_args.= $secret_key;

    my $md5_sign = md5($str_args);
    my $ik_sign = encode_base64($md5_sign, '');

    return $ik_sign;
}

sub getIkPaymentSystems {
    use LWP::UserAgent;
    use MIME::Base64;
    use JSON;
    my $self = shift;

    my ($ik_api_id, $ik_api_key, $ik_cashbox_id) = @_;

    my $remote_url = 'https://api.interkassa.com/v1/paysystem-input-payway?checkoutId=' . $ik_cashbox_id;

    my %headers = (
        'Authorization' => "Basic " . encode_base64("$ik_api_id:$ik_api_key")
    );

    my $browser = LWP::UserAgent->new;
    my $response = $browser->get($remote_url, %headers)->content();

	if(!$response){
	    my %result = ('error' => '<strong style="color:red;">Error!!! System response empty!</strong>');
	    return %result;
	}

    my $json_d = decode_json($response);
    my %json_data = %$json_d;

    if ($json_data{status} ne 'error') {
        my %payment_systems = ();
		if(exists $json_data{data}){
		    my %data_data = %{$json_data{data}};
			foreach my $ps (keys %{$json_data{data}}) {
				my $payment_system = $json_data{data}{$ps}{ser};

				if (!defined $payment_systems{$payment_system}) {
					$payment_systems{$payment_system} = ();

                    my @k_name = (0,1,2);
					foreach my $k (@k_name) {
						if ($json_data{data}{$ps}{name}[$k]{l} eq 'en') {
							$payment_systems{$payment_system}{'title'} = ucfirst( $json_data{data}{$ps}{name}[$k]{v} );
						}
						$payment_systems{$payment_system}{'name'}{ $json_data{data}{$ps}{name}[$k]{l} } = $json_data{data}{$ps}{name}[$k]{v};
					}
				}
				$payment_systems{$payment_system}{'currency'}{ uc( $json_data{data}{$ps}{curAls} ) } = $json_data{data}{$ps}{als};
			}
		}

        if(%payment_systems){
            return %payment_systems;
        } else {
            my %result = ('error' => '<strong style="color:red;">API connection error or system response empty!</strong>');
            return %result;
        }
    } else {
        my %result = ('error' => '<strong style="color:red;">API connection error or system response empty!</strong>');
        if($json_data{message}){
			$result{error} = '<strong style="color:red;">API connection error!<br>' . $json_data{message} . '</strong>';
		}

		return %result;
	}
}

sub check_payment {
    use MIME::Base64;
    use Digest::MD5 qw(md5 md5_hex md5_base64);

    my $self = shift;

    my %form = ();
    foreach my $key(keys %{$self->{FORM}}){
        if ($key =~ m/ik_/){
            my $value = $self->{FORM}->{$key};
            $form{$key} = $value;
        }
    }

    my %form_data = %form;
    my $ik_sign = $form{ik_sign};
    my $ik_key;
    my $str = '';
    my $sign;

    $ik_key = ($form{ik_pw_via} eq 'test_interkassa_test_xts')? $self->{conf}->{PAYSYS_INTERKASSA_TEST_KEY}
        : $self->{conf}->{PAYSYS_INTERKASSA_SECRET_KEY};

    if ($form_data{ik_sign}){ delete $form_data{ik_sign}; }

    foreach my $key (sort keys %form_data) {
        if ($key =~ m/ik_/){ $str.= $form_data{$key} . ':'; }
    }
    $str .= $ik_key;

    my $md5_sign = md5($str);
    $sign = encode_base64($md5_sign, '');

    if ($ik_sign eq $sign && $form{ik_co_id} eq $self->{conf}->{PAYSYS_INTERKASSA_CASHBOX_ID}) {
        if ($form{ik_inv_st} eq 'success') {

            my ($status_code, $payments_id) = main::paysys_pay({
                  PAYMENT_SYSTEM    => $PAYSYSTEM_NAME,
                  PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
                  CHECK_FIELD       => 'UID',
                  USER_ID           => $form{ik_x_user},
                  SUM               => $form{ik_am},
                  EXT_ID            => $form{ik_trn_id} || $form{ik_pm_no},
                  DATA              => \%form,
                  DATE              => $form{ik_inv_prc},
                  CURRENCY          => 1,
                  CURRENCY_ISO      => $form{ik_cur},
                  MK_LOG            => 1,
                  PAYMENT_ID        => 1,
                  PAYMENT_DESCRIBE  => $form{ik_desc} || $self->{PAYMENT_SYSTEM},
            });
        }
    }

  return 1;
}

sub get_settings {
  my %SETTINGS = ();

  $SETTINGS{VERSION} = $PAYSYSTEM_VERSION;
  $SETTINGS{ID}      = $PAYSYSTEM_ID;
  $SETTINGS{NAME}    = $PAYSYSTEM_NAME;

  $SETTINGS{CONF} = \%PAYSYSTEM_CONF;

  return %SETTINGS;
}

1
