const { registerValidation, loginValidation, updateProfileValidation, fotoPerfilValidation } = require('../../src/validators/authValidator');
const handleValidation = require('../../src/validators/validationResult');
const { mockResponse } = require('./helpers');

async function validate(rules, body) {
  const req = { body };
  for (const rule of rules) {
    await rule.run(req);
  }
  const res = mockResponse();
  const next = jest.fn();
  handleValidation(req, res, next);
  const errors = res.json.mock.calls[0]?.[0]?.errors || [];
  return { req, res, next, fields: [...new Set(errors.map((e) => e.field))] };
}

describe('validators/authValidator', () => {
  describe('registerValidation', () => {
    const valido = { nome: 'Responsável Demo', email: 'responsavel@demo.com', senha: '123456' };

    test('aceita dados válidos sem telefone', async () => {
      const { next, res } = await validate(registerValidation, valido);
      expect(next).toHaveBeenCalled();
      expect(res.status).not.toHaveBeenCalled();
    });

    test.each([
      '(11) 98765-4321',
      '11987654321',
      '(11) 3456-7890',
      '+55 11 98765-4321',
    ])('aceita telefone válido: %s', async (telefone) => {
      const { next } = await validate(registerValidation, { ...valido, telefone });
      expect(next).toHaveBeenCalled();
    });

    test.each(['123', 'abc', '(11) 9876', '11-98765-4321-99999'])('rejeita telefone inválido: %s', async (telefone) => {
      const { res, fields } = await validate(registerValidation, { ...valido, telefone });
      expect(res.status).toHaveBeenCalledWith(400);
      expect(fields).toEqual(['telefone']);
    });

    test('rejeita nome curto, e-mail inválido e senha curta', async () => {
      const { res, next, fields } = await validate(registerValidation, { nome: 'A', email: 'invalido', senha: '123' });
      expect(res.status).toHaveBeenCalledWith(400);
      expect(next).not.toHaveBeenCalled();
      expect(fields).toEqual(['nome', 'email', 'senha']);
    });

    test('remove espaços do nome antes de validar', async () => {
      const { fields } = await validate(registerValidation, { ...valido, nome: '  A  ' });
      expect(fields).toEqual(['nome']);
    });
  });

  describe('loginValidation', () => {
    test('aceita e-mail e senha preenchidos', async () => {
      const { next } = await validate(loginValidation, { email: 'responsavel@demo.com', senha: 'x' });
      expect(next).toHaveBeenCalled();
    });

    test('exige e-mail válido e senha', async () => {
      const { res, fields } = await validate(loginValidation, { email: '', senha: '' });
      expect(res.status).toHaveBeenCalledWith(400);
      expect(fields).toEqual(['email', 'senha']);
    });
  });

  describe('updateProfileValidation', () => {
    test('aceita telefone vazio (opcional)', async () => {
      const { next } = await validate(updateProfileValidation, { nome: 'Novo Nome', telefone: '' });
      expect(next).toHaveBeenCalled();
    });

    test('exige nome', async () => {
      const { fields } = await validate(updateProfileValidation, {});
      expect(fields).toEqual(['nome']);
    });
  });

  describe('fotoPerfilValidation', () => {
    const dataUrl = (tipo, bytes) => `data:${tipo};base64,${Buffer.from(bytes).toString('base64')}`;
    const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13];

    test.each([
      ['PNG', dataUrl('image/png', png)],
      ['JPEG', dataUrl('image/jpeg', [0xff, 0xd8, 0xff, 0xe0, 0, 16])],
      ['WEBP', dataUrl('image/webp', [...Buffer.from('RIFF'), 0, 0, 0, 0, ...Buffer.from('WEBPVP8 ')])],
    ])('aceita imagem %s em Data URL', async (_, foto_perfil) => {
      const { next } = await validate(fotoPerfilValidation, { foto_perfil });
      expect(next).toHaveBeenCalled();
    });

    test.each([
      ['ausente', undefined],
      ['que não é Data URL', 'minha-foto.png'],
      ['GIF (tipo não suportado)', dataUrl('image/gif', [...Buffer.from('GIF89a')])],
      ['com conteúdo que não é imagem', dataUrl('image/png', [...Buffer.from('não sou uma imagem')])],
      ['enviada como lista', [dataUrl('image/png', png)]],
    ])('rejeita foto %s', async (_, foto_perfil) => {
      const { res, fields } = await validate(fotoPerfilValidation, { foto_perfil });
      expect(res.status).toHaveBeenCalledWith(400);
      expect(fields).toEqual(['foto_perfil']);
    });

    test('rejeita imagem maior que 512 KB', async () => {
      const grande = Buffer.concat([Buffer.from(png), Buffer.alloc(512 * 1024)]);
      const { fields } = await validate(fotoPerfilValidation, { foto_perfil: dataUrl('image/png', grande) });
      expect(fields).toEqual(['foto_perfil']);
    });
  });

  describe('handleValidation', () => {
    test('retorna mensagem padrão e lista de erros com field/message', async () => {
      const { res } = await validate(loginValidation, { email: 'x', senha: '1' });
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Dados inválidos.',
        errors: [{ field: 'email', message: 'E-mail inválido.' }],
      });
    });
  });
});
