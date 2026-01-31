class Api::V1::DataController < ApplicationController

  PERPAGE = 20

  after_action :track_action

  def ping

    p "*** params -> #{params}"
    f = DateTime.now.to_f
    app_info = AppInfo.first
    user =  Uid.find_by(uid: params[:unique_id]).user rescue nil

    if user.nil?
      user = Uid.new_user(params[:unique_id], params[:datum])
      p "user #{user}, nome-> #{user.nome}"
    end

    p "user creted? -> #{user}"

    res = {message: 'ping', timer: f, user: user.nickname, welcome_message: app_info.welcome_message.body.to_html }
    p "*** RES: #{res}"
    render json: res, status: :ok

  end

  def app_info
    app_info = AppInfo.first

    res = { about_text: app_info.app_description.body.to_html, terms_text: app_info.use_terms.body.to_html}

    render json: res, status: :ok
  end

  def edit_user
    uid = Uid.find_by(uid: params[:uuid]) rescue nil
    if uid.present?
      user = uid.user
      res = {message: 'success', is_temporary: user.created_at == user.updated_at ? true : false, nome: user.nome, email: user.email, nickname: user.nickname, nascimento: user.nascimento}
    else
      res = {message: 'fail'}
    end
    render json: res, status: :ok
  end

  def update_user
    uid = Uid.find_by(uid: params[:uuid]) rescue nil
    if uid.present?
      user = uid.user
      if user.update(user_params)
        res = { message: 'success', is_temporary: user.created_at == user.updated_at ? true : false, nome: user.nome, email: user.email, nickname: user.nickname}
        status = :ok
      else
        res = {message: 'unprocessed data', errors: user.errors.messages}
        status = :unprocessable_entity
      end
    else
      res = { message: 'uuid not found' }
      status = :unprocessable_entity
    end
    render json: res, status: status
  end

  def medicamentos_search

    res = []
    page = params[:page] ||= 0
    nome = params[:q]
    medicamentos = Bula.includes(:bula_cc_datum)
                   .where("denominacao ILIKE :query", query: "%#{nome}%")
                   .order(:denominacao)
                   .offset(page.to_i * PERPAGE)
                   .limit(PERPAGE)
    medicamentos.each do |k|
      res << {id: k.id, nome: k.denominacao, present: k.bula_cc_datum.any?, versions: k.bula_cc_datum.count}
    end

    render json: res, status: :ok
  end

  def bula_versoes
    res = []
    medicamento = Bula.find(params[:medicamento_id]) rescue nil
    bula_versoes = medicamento.bula_cc_datum.order(data_publicacao: :desc) rescue nil
    if bula_versoes.any?
      bula_versoes.each do |k|
        res << {bula_id: k.id, date: k.data_publicacao, laboratorio: k.laboratorio }
      end
      p "********"
      p res
      render json: res, status: :ok
    else
      #gravar alerta de que a bula foi procurada e não localizada no sistema
      render json: {error: 'Nenuma bula localizada'}, status: :not_found
      p "*** Nenhuma bula localizada!"
    end
  end

  def detalhes_bula
    cc = BulaCcDatum.find(params[:bula_id]) rescue nil

    if cc.present?
      nome_medicamento = cc.bula.denominacao.strip.upcase
      query_params = ERB::Util.url_encode(nome_medicamento).gsub('%20', '+')
      url_anvisa = "https://consultas.anvisa.gov.br/#/bulario/q/?nomeProduto=#{query_params}"
      pdf_url = cc.pdf_bula.attached? ? Rails.application.routes.url_helpers.rails_storage_proxy_url(cc.pdf_bula, host: request.base_url) : nil

      puts '*******************************'
       h = {present: true, resumo: cc.resumo.body.to_html, curiosidades: cc.curiosidades.body.to_html, url_busca: url_anvisa, pdf_url: pdf_url }
      puts h
      render json:  {present: true, resumo: cc.resumo.body.to_html, curiosidades: cc.curiosidades.body.to_html, url_busca: url_anvisa, pdf_url: pdf_url }, status: :ok
    else
      render json: {error: 'Bula não localizada' }, status: :not_found
    end

  end

  private

  def user_params
    params.permit(:nome, :email, :nickname, :password, :password_confirmation)
  end


  protected

  def track_action
    ahoy.track "api data", request.path_parameters

    p "AHOY #{request.path_parameters}"
  end
end
