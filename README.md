# Syracuse Land Value Taxation Experiment

Hi. This is just some math I did. It is probably very wrong. I don't know anything about land assessments or taxes.

This script calculates two methods of land value taxation for the city of Syracuse. All of this output is included
in the file [syracuse_lvt_output.csv](syracuse_lvt_output.csv). The column `city_lvt_pure` is a flat 2.67% tax on all
assessed land value in the city. `city_lvt_with_exemptions` is a 4.64% tax on land value with exemptions roughly proportional
to the current ones. So veterans get the 15% exemption, and hospitals still pay nothing.

After each of those, we calculate the estimate increase in tax on the property (a negative number means a tax decrease). So
`tax_hike_from_lvt_pure` and `tax_hike_from_lvt_with_exemptions` are the real calculations.

To make a long spreadsheet short, if your land value is 20% or more of your total property value, your tax goes up, otherwise
it goes down.

## Reproducing the calculations
- You'll need sqlite3 in your path. `apt-get install sqlite3` if you're on an OS like that? On Mac use Homebrew? On Windows
use whatever you use on Windows?
- You'll need input data. I got mine from [syrgov.net](http://data.syrgov.net/datasets/f8a69e7bd20c4250a151f8275174ec0c_0) and
downloaded it to a 21 MiB CSV file.
- `./run_calculations.sh your_input_file.csv your_output_file.csv`


Happy calculating.
