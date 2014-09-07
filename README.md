Automatic book information retriever
====================================

Authors
-------
* [Dominik Zajíček](https://github.com/zaijo)
* [Martin Habovštiak](https://github.com/Kixunil) <martin.habovstiak@gmail.com>

Description
-----------

This project purpose is to help us create database of books in [Progressbar hackerspace](https://progressbar.sk). We decided to search books based on barcode because we have a barcode scanner in Progressbar.

Feel free to use the script or contribute! If you want help with scanning barcodes don't hesitate to contact us.

Dependencies
------------

* bash and other Unix tools
* wget
* bc

Example
-------

You can try it on our real life data. :)

```
wget -qO - http://pastebin.com/raw.php?i=t4vxUNiX | tr -d '\r'| ./books.sh -
```

Warning
-------

Usage of this script for massive data mining may be prohibited by site owners. We advise you not to run it too often or on large data input. You should probably avoid using database commercialy too.

License (MIT)
-------------
Copyright (C) 2014 Dominik Zajíček, Martin Habovštiak

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


