//= require quagga

$(document).on('turbolinks:load ajax:loaded loaded.mylibrary.mylibrary-modal', function(){
  $('[data-quagga]').on('click', function(event) {
    event.preventDefault();

    Quagga.init({
        inputStream : {
          name : "Live",
          type : "LiveStream",
          size: 1024,
          target: document.querySelector('#barcode-scanner-preview')    // Or '#yourElement' (optional)
        },
        decoder : {
          readers : [
            'code_39_reader',
            'code_39_vin_reader'
          ]
        },
        locate: true,
        halfSample: false,
        patchSize: "large" // x-small, small, medium, large, x-large
      }, function(err) {
          if (err) {
              console.log(err);
              return
          }
          Quagga.onDetected(function(data) { $('#barcode').val(data.codeResult.code); $('#barcode').closest('form').submit(); });
          Quagga.start();
      });
  });
});
