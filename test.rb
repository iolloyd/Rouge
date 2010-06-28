require 'rouge'
cmds = [
    
    {'group' => 'wine', 
     'data'  => {
         'name'    => 'super',
         'grape'   => 'valpolicella',
         'price'   => '23.00',
         'year'    => '1998',
         'flavour' => 'cherry',
         'region'  => 'roma',
         'country' => 'italy'}
    },

    {'group' => 'wine', 
     'data' => {
         'name'    => 'woofer',
         'grape'   => 'shiraz',
         'price'   => '22.00',
         'year'    => '2001',
         'flavour' => 'chocolate',
         'region'  => 'alcoy',
         'country' => 'spain'}
    },

    {'group' => 'wine', 
     'data'  => {
         'name'    => 'fuffer',
         'grape'   => 'shiraz',
         'price'   => '8.00',
         'year'    => '1999',
         'flavour' => 'nuts',
         'region'  => 'ottawotta',
         'country' => 'italy'}
    }

]

r = Rouge.new

# Clear the database of all data for testing
r.cmd "flushall"

# Add some data ...
cmds.each do |x|
    group, data = x['group'], x['data']
    r.store_record(group, data)
end

# These are the bits of info I want from the database
fields_I_want = ["price", "year", "grape"]

# I want the first highest priced wines
p r.sort("wine", "price", 0, 3, fields_I_want)
