require 'nokogiri'
require 'csv'

lastConcept = nil
currentConcept = nil
builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
  xml['rdf'].RDF('xmlns:skos' => 'http://www.w3.org/2004/02/skos/core#', 'xmlns:rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#') {
    CSV.foreach(ARGV[0], { :col_sep => "\t", :headers=>:first_row}) do |row|
      if lastConcept != row[0] && row[0] != nil
        lastConcept = row[0].strip
        xml['skos'].Concept('rdf:about' => lastConcept) do |inner|
          currentConcept = inner.parent
          
          # generate alternative labels by stripping off common prefixes
          labelValue = lastConcept
          prefix_groups = lastConcept.scan(/^(unc|department of|school of|college of|curriculum in|curriculum for|division of|center for|program in)\s+(\bthe\b)?\s*(.+)/i)
          if prefix_groups.length > 0
            labelValue = prefix_groups[0][2]
            xml['skos'].hiddenLabel labelValue
          end
          
          labelValue = lastConcept.sub(/\s*((phd|master's|graduate)? program)$/i, "")
          if labelValue != lastConcept
            xml['skos'].hiddenLabel labelValue
          end
        end
      else
        value = row[2]
        if row[1] != nil && value != nil
          value = value.strip
          
          if row[1] == "NT"
            xb = Nokogiri::XML::Builder.new({}, currentConcept)
            xb.narrower('rdf:resource' => value)
          elsif row[1] == "BT"
            xb = Nokogiri::XML::Builder.new({}, currentConcept)
            xb.broader('rdf:resource' => value)
          elsif row[1] != nil && row[1].casecmp("USE") == 0
            xb = Nokogiri::XML::Builder.new({}, currentConcept)
            xb.prefLabel value
          elsif row[1] != nil && row[1].casecmp("UF") == 0
            xb = Nokogiri::XML::Builder.new({}, currentConcept)
            xb.altLabel value
          end
        end
      end
    end
  }
end
puts builder.to_xml(:indent => 2)