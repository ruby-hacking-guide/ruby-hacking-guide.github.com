#!/usr/bin/env ruby
# -*- coding: utf-8 -*- vim:set encoding=utf-8:
$KCODE = 'u'

ISOLanguage = 'en-US'

$LOAD_PATH.unshift('../lib')
require 'rhg_html_gen'

FOOTER = <<EOS
<hr>

The original work is Copyright &copy; 2002 - 2004 Minero AOKI.<br>
Translated by $tag(translated by)$<br>
<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/2.5/"><img alt="Creative Commons License" border="0" src="images/somerights20.png"/></a><br/>This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/2.5/">Creative Commons Attribution-NonCommercial-ShareAlike2.5 License</a>.

</body>
</html>
EOS

$tags['language'] = 'en'
$tags['generation day'] = Time.now.strftime("%Y-%d-%m")

TranslatedByRE = /^Translated by (.+)$/

make(*ARGV) if __FILE__ == $0
