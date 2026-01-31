class Ahoy::Store < Ahoy::DatabaseStore
=begin
  def track_visit(data)
    p "**** track_visit ***"
    p data
    visita = Ahoy::Visit.where(visit_token: data[:visit_token] )

    #utilizar data para exibir a linha no broadcast

    #envia a visita para monitoramento do admin
    broadcast_prepend_to("main-adm-stats", target: 'visitas-data', partial: 'admin/stats/broadcast_visitas_data', locals: { k: visita, stats_target: true })

  end
=end
end

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = true


Ahoy.api_only = true
