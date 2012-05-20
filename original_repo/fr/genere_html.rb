#!/usr/bin/env ruby
# -*- coding: utf-8 -*- vim:set encoding=utf-8:
$KCODE = 'u'

ISOLanguage = 'fr-FR'

$LOAD_PATH.unshift('../lib')
require 'rhg_html_gen'

FOOTER = <<EOS
<hr>

L'oeuvre originale est sous Copyright &copy; 2002 - 2004 Minero AOKI.<br>
Traduction $tag(translated by)$<br>
<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/2.5/"><img alt="Creative Commons License" border="0" src="images/somerights20.fr.png"/></a><br/>Cette oeuvre est sous la <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/2.5/deed.fr">Licence Creative Commons Attribution-NonCommercial-ShareAlike2.5</a>.

</body>
</html>
EOS

$tags['generation day'] = Time.now.strftime("%d/%m/%Y")
$tags['language'] = 'fr'

TranslatedByRE = /^Traduction (.+)$/

make(*ARGV) if __FILE__ == $0
