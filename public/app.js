(function(window, $){

	var deltaHelm = 2;
	
	window.onload = function(){

		// Refresh helm position's display every 2 seconds;
		window.setInterval('displayHelmPosition()', 2000);

		$('#btn_helm_babord').click(function(){
			$.get( deltaHelm+'/helm', function( data ) {
				displayHelmPosition(data);
			});
		});

		$('#btn_helm_tribord').click(function(){
			$.get( '-'+deltaHelm+'/helm', function( data ) {
				displayHelmPosition(data);
			});
		});

	}

	window.displayHelmPosition = function(pos){
		if (pos!==undefined){
			$('#val_helm_position').html(pos);
		}
		else{
			$.get('0/helm', function( data ) {
				$('#val_helm_position').html(data);
			});
		}
	}

})(window, jQuery);