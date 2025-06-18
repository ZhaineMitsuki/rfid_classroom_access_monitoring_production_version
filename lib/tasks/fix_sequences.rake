namespace :db do
  desc "Fix PostgreSQL sequences for all tables"
  task fix_sequences: :environment do
    puts "🔧 Fixing PostgreSQL sequences..."

    # Get all tables with id columns
    tables_with_sequences = []
    
    ActiveRecord::Base.connection.tables.each do |table|
      # Skip system tables
      next if table.start_with?('pg_', 'information_schema')
      next if %w[ar_internal_metadata schema_migrations].include?(table)
      
      # Check if table has an id column
      if ActiveRecord::Base.connection.column_exists?(table, :id)
        tables_with_sequences << table
      end
    end

    puts "📊 Found #{tables_with_sequences.length} tables with ID sequences"

    tables_with_sequences.each do |table|
      begin
        # Get the maximum ID from the table
        max_id = ActiveRecord::Base.connection.execute("SELECT COALESCE(MAX(id), 0) FROM #{table}").first['coalesce']
        
        # Set the sequence to max_id + 1
        sequence_name = "#{table}_id_seq"
        next_val = max_id.to_i + 1
        
        ActiveRecord::Base.connection.execute("SELECT setval('#{sequence_name}', #{next_val}, false)")
        
        puts "✅ Fixed #{table}: max_id=#{max_id}, next_val=#{next_val}"
        
      rescue => e
        puts "❌ Error fixing #{table}: #{e.message}"
      end
    end

    puts "\n🎉 Sequence fixing completed!"
    puts "\n📋 Current sequence values:"
    
    tables_with_sequences.each do |table|
      begin
        sequence_name = "#{table}_id_seq"
        result = ActiveRecord::Base.connection.execute("SELECT last_value, is_called FROM #{sequence_name}").first
        max_id = ActiveRecord::Base.connection.execute("SELECT COALESCE(MAX(id), 0) FROM #{table}").first['coalesce']
        
        puts "#{table}: sequence=#{result['last_value']} (called=#{result['is_called']}), max_id=#{max_id}"
      rescue => e
        puts "#{table}: Error - #{e.message}"
      end
    end
  end

  desc "Check sequence status for all tables"
  task check_sequences: :environment do
    puts "📊 Checking PostgreSQL sequences..."
    
    ActiveRecord::Base.connection.tables.each do |table|
      next if table.start_with?('pg_', 'information_schema')
      next if %w[ar_internal_metadata schema_migrations].include?(table)
      next unless ActiveRecord::Base.connection.column_exists?(table, :id)
      
      begin
        sequence_name = "#{table}_id_seq"
        result = ActiveRecord::Base.connection.execute("SELECT last_value, is_called FROM #{sequence_name}").first
        max_id = ActiveRecord::Base.connection.execute("SELECT COALESCE(MAX(id), 0) FROM #{table}").first['coalesce']
        count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}").first['count']
        
        status = max_id.to_i >= result['last_value'].to_i ? "❌ CONFLICT" : "✅ OK"
        
        puts "#{table.ljust(20)} | seq: #{result['last_value'].to_s.ljust(5)} | max: #{max_id.to_s.ljust(5)} | count: #{count.to_s.ljust(5)} | #{status}"
      rescue => e
        puts "#{table.ljust(20)} | Error: #{e.message}"
      end
    end
  end
end 