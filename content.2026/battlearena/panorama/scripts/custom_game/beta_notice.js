function SetLocalizedText() {
	$('#BetaNoticeTitle1').text = $.Localize('#aa_beta_title1');
	$('#BetaNoticeFun').text = $.Localize('#aa_beta_fun');
	$('#BetaNoticeTitle2').text = $.Localize('#aa_beta_title2');
	$('#BetaNoticeSubtitle').text = $.Localize('#aa_beta_subtitle');
	$('#BetaNoticeText1').text = $.Localize('#aa_beta_text1');
	$('#BetaNoticeText2').text = $.Localize('#aa_beta_text2');
	$('#BetaNoticeThanks').text = $.Localize('#aa_beta_thanks');
	$('#BetaNoticeContinue').text = $.Localize('#aa_beta_continue');
}

function BetaNoticeShow() {
	SetLocalizedText();
	var panel = $('#BetaNoticePanel');
	if (panel) {
		panel.visible = true;
		return true;
	}
	return false;
}

function BetaNoticeHide() {
	var panel = $('#BetaNoticePanel');
	if (panel) panel.visible = false;
}

GameEvents.Subscribe('show_beta_notice', function() {
	if (!BetaNoticeShow()) {
		$.Schedule(0.5, function TryAgain() {
			if (!BetaNoticeShow()) $.Schedule(0.5, TryAgain);
		});
	}
});

(function() {
	var tries = 0;
	function DelayedShow() {
		if (!BetaNoticeShow() && tries < 10) {
			tries++;
			$.Schedule(1, DelayedShow);
		}
	}
	$.Schedule(3, DelayedShow);
})();
